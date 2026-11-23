import json
import threading
import time
from datetime import timedelta
from typing import Any

import redis
import structlog
from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone
from pydantic import SecretStr, ValidationError

from newsplatform.accounts.models import User
from newsplatform.approvals import services as approvals
from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit.services import record
from newsplatform.common.crypto import decrypt, encrypt
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.common.redis import bus
from newsplatform.integrations.base import Provider, ProviderConfig, Test, providers
from newsplatform.integrations.models import (
    ConfigStatus,
    IntegrationConfig,
    IntegrationTestRun,
    IntegrationVersion,
    RunStatus,
)
from newsplatform.rbac import selectors as rbac

log = structlog.get_logger(__name__)
_CHANNEL = "integrations:changed"
_TTL = 60.0


def get_provider(key: str) -> Provider[Any]:
    try:
        return providers()[key]
    except KeyError as exc:
        raise NotFound("Unknown integration") from exc


def _ctx(config: IntegrationConfig) -> dict[str, str]:
    return {
        "purpose": "integration",
        "config": str(config.pk),
        "provider": config.provider,
        "environment": config.environment,
    }


def _secrets(version: IntegrationVersion | None) -> dict[str, str]:
    if version is None or not version.secrets:
        return {}
    data: dict[str, str] = json.loads(decrypt(version.secrets, _ctx(version.config)))
    return data


def _hint(secret: str) -> str:
    return "••••" + (secret[-4:] if len(secret) >= 16 else "")


def build(version: IntegrationVersion) -> Any:
    provider = get_provider(version.config.provider)
    return provider.config_model.model_validate({**version.fields, **_secrets(version)})


def latest_version(config: IntegrationConfig) -> IntegrationVersion | None:
    return config.versions.select_related("config").order_by("-number").first()


@transaction.atomic
def save_draft(
    *,
    actor: User,
    provider_key: str,
    fields: dict[str, Any],
    secrets: dict[str, str | None],
    base_number: int,
) -> IntegrationVersion:
    """Secrets are write-only: omitted keeps the stored value, null clears it."""
    rbac.require(actor, "integrations.manage")
    provider = get_provider(provider_key)
    names = provider.config_model.secret_fields()
    if names & fields.keys() or secrets.keys() - names:
        raise DomainError("Secrets must be sent separately.", code="validation_error")
    IntegrationConfig.objects.get_or_create(provider=provider_key, environment=settings.ENVIRONMENT)
    config = IntegrationConfig.objects.select_for_update().get(
        provider=provider_key, environment=settings.ENVIRONMENT
    )
    previous = latest_version(config)
    if (previous.number if previous else 0) != base_number:
        raise Conflict("Someone else changed this. Reload and try again.", code="stale_version")
    merged = {**_secrets(previous), **{k: v for k, v in secrets.items() if v}}
    for name, value in secrets.items():
        if not value:
            merged.pop(name, None)
    try:
        parsed = provider.config_model.model_validate({**fields, **merged})
    except ValidationError as exc:
        # `input` is dropped: it could echo a secret back.
        raise DomainError(
            "The configuration is invalid.",
            code="validation_error",
            errors=[{"field": ".".join(map(str, e["loc"])), "message": e["msg"]} for e in exc.errors()],
        ) from exc
    plain = {k: v for k, v in parsed.model_dump(mode="json").items() if k not in names}
    version = IntegrationVersion.objects.create(
        config=config,
        number=base_number + 1,
        schema_version=provider.schema_version,
        fields=plain,
        secrets=encrypt(json.dumps(merged).encode(), _ctx(config)) if merged else None,
        secret_hints={k: _hint(v) for k, v in merged.items()},
        created_by=actor,
    )
    old = previous.fields if previous else {}
    changed = sorted(k for k in plain.keys() | old.keys() if plain.get(k) != old.get(k))
    record(
        actor=actor,
        action="integration.draft_saved",
        target=config,
        label=provider_key,
        before={k: old.get(k) for k in changed},
        after={
            **{k: plain.get(k) for k in changed},
            "version": version.number,
            "secrets_changed": sorted(secrets),
        },
    )
    return version


@transaction.atomic
def start_test(*, actor: User, version: IntegrationVersion, params: dict[str, Any]) -> IntegrationTestRun:
    from newsplatform.integrations.tasks import run_test

    rbac.require(actor, "integrations.manage")
    provider = get_provider(version.config.provider)
    if missing := [p for p in provider.test_params if not params.get(p)]:
        raise DomainError(
            "Missing test input",
            code="validation_error",
            errors=[{"field": m, "message": "Required"} for m in missing],
        )
    # A worker that died mid-test must not block testing forever.
    cutoff = timezone.now() - timedelta(minutes=6)
    version.test_runs.filter(status__in=[RunStatus.QUEUED, RunStatus.RUNNING], created_at__lt=cutoff).update(
        status=RunStatus.FAILED, finished_at=timezone.now()
    )
    try:
        with transaction.atomic():
            run = IntegrationTestRun.objects.create(
                version=version, started_by=actor, params={k: params[k] for k in provider.test_params}
            )
    except IntegrityError as exc:
        raise Conflict("A test is already running.", code="test_running") from exc
    record(
        actor=actor,
        action="integration.tested",
        target=version.config,
        label=version.config.provider,
        after={"version": version.number},
    )
    transaction.on_commit(lambda: run_test.delay(str(run.pk)))
    return run


def execute_test(run_id: str) -> None:
    run = IntegrationTestRun.objects.select_related("version__config").get(pk=run_id)
    if run.status != RunStatus.QUEUED:
        return  # redelivered by the broker
    run.status = RunStatus.RUNNING
    run.save(update_fields=["status", "updated_at"])

    def emit(steps: list[Any]) -> None:
        run.steps = [s.as_dict() for s in steps]
        run.save(update_fields=["steps", "updated_at"])

    config = run.version.config
    test = Test(config.provider, emit)
    if test.step("load", "Load configuration", "Pakia usanidi", lambda: str(build(run.version) and "Valid")):
        get_provider(config.provider).test(build(run.version), test, run.params)
    emit(test.steps)
    with transaction.atomic():
        run.status = RunStatus.PASSED if test.passed else RunStatus.FAILED
        run.finished_at = timezone.now()
        run.save()
        config = IntegrationConfig.objects.select_for_update().get(id=config.id)
        config.last_tested_at, config.last_test_passed = run.finished_at, test.passed
        if config.active_version_id == run.version_id:
            config.status = ConfigStatus.ACTIVE if test.passed else ConfigStatus.FAILING
        config.save()


def last_test(version: IntegrationVersion) -> IntegrationTestRun | None:
    return version.test_runs.filter(finished_at__isnull=False).order_by("-created_at").first()


def _check_activatable(actor: User, version: IntegrationVersion, override_reason: str) -> None:
    run = last_test(version)
    if run and run.status == RunStatus.PASSED:
        return
    if not override_reason:
        raise Conflict("Run the test successfully before activating.", code="test_not_passed")
    rbac.require(actor, "integrations.override_test")
    if len(override_reason.strip()) < 10:
        raise DomainError("Explain the override in at least 10 characters.", code="validation_error")


def _activate(version: IntegrationVersion, actor: User, approved_by: User | None, override: str) -> None:
    config = IntegrationConfig.objects.select_for_update().get(pk=version.config.pk)
    newest = latest_version(config)
    if newest is None or newest.pk != version.pk:
        raise Conflict("A newer version exists. Review that one instead.", code="stale_version")
    run = last_test(version)
    before = (
        config.versions.filter(pk=config.active_version_id).values_list("number", flat=True).first()
        if config.active_version_id
        else None
    )
    config.active_version = version
    config.status = ConfigStatus.ACTIVE if run and run.status == RunStatus.PASSED else ConfigStatus.FAILING
    config.save()
    record(
        actor=actor,
        approved_by=approved_by,
        action="integration.activated",
        target=config,
        label=config.provider,
        before={"version": before},
        after={"version": version.number},
        reason=override,
    )
    transaction.on_commit(lambda: _announce(config.provider))
    if config.provider == "aws_waf":
        from newsplatform.staff_security.tasks import sync_waf_allowlist

        transaction.on_commit(sync_waf_allowlist.delay)


@transaction.atomic
def activate(
    *, actor: User, version: IntegrationVersion, override_reason: str = ""
) -> IntegrationConfig | ApprovalRequest:
    rbac.require(actor, "integrations.manage")
    _check_activatable(actor, version, override_reason)
    if approvals.is_required("integration.activate"):
        return approvals.request_approval(
            actor=actor,
            action="integration.activate",
            dedupe_key=str(version.config_id),
            summary=f"Activate {get_provider(version.config.provider).name} v{version.number}",
            payload={"version": str(version.pk), "override_reason": override_reason},
            reason=override_reason,
        )
    _activate(version, actor, None, override_reason)
    return IntegrationConfig.objects.get(pk=version.config_id)


@approvals.register("integration.activate", "integrations.manage")
def _execute(payload: dict[str, Any], requester: User, approver: User) -> None:
    version = IntegrationVersion.objects.select_related("config").get(pk=payload["version"])
    _check_activatable(requester, version, payload["override_reason"])
    _activate(version, requester, approver, payload["override_reason"])


# ---- runtime access -------------------------------------------------------------------------------------
# Decrypted configs live only in process memory. Redis carries the "something changed" signal, never secrets.
_cache: dict[str, tuple[float, Any]] = {}
_lock = threading.Lock()
_listener: threading.Thread | None = None


def _announce(provider: str) -> None:
    _cache.pop(provider, None)
    try:
        bus().publish(_CHANNEL, provider)
    except redis.RedisError:
        log.warning("integration_invalidate_failed", provider=provider)  # the TTL still bounds staleness


def _listen() -> None:
    while True:
        try:
            pubsub = redis.Redis.from_url(
                settings.BROKER_URL, decode_responses=True, socket_connect_timeout=2, health_check_interval=15
            ).pubsub(ignore_subscribe_messages=True)
            pubsub.subscribe(_CHANNEL)
            _cache.clear()  # anything missed while disconnected
            for message in pubsub.listen():  # type: ignore[no-untyped-call]
                _cache.pop(str(message["data"]), None)
        except redis.RedisError:
            time.sleep(5)


def _ensure_listener() -> None:
    global _listener
    if _listener is None or not _listener.is_alive():
        _listener = threading.Thread(target=_listen, daemon=True, name="integration-cache")
        _listener.start()


def get_active[C: ProviderConfig](provider: str, model: type[C]) -> C | None:
    with _lock:
        _ensure_listener()
        hit = _cache.get(provider)
    if hit and time.monotonic() - hit[0] < _TTL:
        return hit[1] if isinstance(hit[1], model) else None
    row = (
        IntegrationConfig.objects.select_related("active_version__config")
        .filter(provider=provider, environment=settings.ENVIRONMENT, active_version__isnull=False)
        .first()
    )
    value = build(row.active_version) if row and row.active_version else None
    _cache[provider] = (time.monotonic(), value)
    return value if isinstance(value, model) else None


def schema_for(provider: Provider[Any]) -> dict[str, Any]:
    """A flat field list for the admin form, so a new provider needs no UI code."""
    names, schema = provider.config_model.secret_fields(), provider.config_model.model_json_schema()
    out = []
    for name, spec in schema["properties"].items():
        kind = (
            "secret"
            if name in names
            else {"integer": "integer", "boolean": "boolean"}.get(spec.get("type", ""), "text")
        )
        out.append(
            {
                "name": name,
                "kind": kind,
                "label_en": spec.get("title", name),
                "label_sw": spec.get("x-title-sw", spec.get("title", name)),
                "help_en": spec.get("description", ""),
                "help_sw": spec.get("x-help-sw", ""),
                "is_required": name in schema.get("required", []),
                "default": spec.get("default"),
            }
        )
    return {"fields": out, "test_params": provider.test_params}


__all__ = ["SecretStr", "activate", "execute_test", "get_active", "save_draft", "start_test"]
