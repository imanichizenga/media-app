"""The provider contract. Business code asks for a typed config; it never knows which vendor is behind it."""

import time
from abc import ABC, abstractmethod
from collections.abc import Callable, Iterator
from contextlib import contextmanager, suppress
from dataclasses import asdict, dataclass
from typing import Any, ClassVar

import redis
import structlog
from botocore.exceptions import BotoCoreError, ClientError
from django.db import DatabaseError, transaction
from pydantic import BaseModel, ConfigDict, SecretStr

from newsplatform.common import context
from newsplatform.common.errors import ServiceUnavailable
from newsplatform.common.logging import redact_text
from newsplatform.common.redis import cache
from newsplatform.integrations import hints

log = structlog.get_logger(__name__)


class ProviderConfig(BaseModel):
    model_config = ConfigDict(extra="forbid", frozen=True, str_strip_whitespace=True)

    @classmethod
    def secret_fields(cls) -> set[str]:
        return {n for n, f in cls.model_fields.items() if SecretStr in (f.annotation, *_args(f.annotation))}


def _args(annotation: Any) -> tuple[Any, ...]:
    from typing import get_args

    return get_args(annotation)


STEP_STATUSES = [(s, s) for s in ("pending", "running", "passed", "failed", "skipped")]


@dataclass(slots=True)
class Step:
    key: str
    label_en: str
    label_sw: str
    status: str = "pending"  # pending | running | passed | failed | skipped
    latency_ms: int = 0
    detail: str = ""
    remediation: str = ""

    def as_dict(self) -> dict[str, Any]:
        return {**asdict(self), "remediation_sw": hints.SW.get(self.remediation, self.remediation)}


class StepFailed(Exception):
    def __init__(self, detail: str, remediation: str = "") -> None:
        super().__init__(detail)
        self.detail, self.remediation = detail, remediation


_HINTS = {
    "AccessDenied": "Grant the missing IAM action to the role or key this platform uses.",
    "AccessDeniedException": "Grant the missing IAM action to the role or key this platform uses.",
    "403": "Grant the missing IAM action to the role or key this platform uses.",
    "NoSuchBucket": "Check the bucket name and region.",
    "InvalidAccessKeyId": "The access key does not exist. Create a new one or use the task role.",
    "SignatureDoesNotMatch": "The secret key does not match the access key. Paste it again.",
    "ExpiredToken": "The credentials have expired.",
    "PermanentRedirect": "The bucket is in another region. Correct the region field.",
    "MessageRejected": "Verify the sender identity, and request SES production access if in the sandbox.",
}


def describe_error(exc: Exception) -> tuple[str, str]:
    if isinstance(exc, StepFailed):
        return exc.detail, exc.remediation
    if isinstance(exc, ClientError):
        err = exc.response.get("Error", {})
        code = str(err.get("Code", ""))
        return redact_text(f"{code}: {err.get('Message', '')}"), _HINTS.get(code, "")
    if isinstance(exc, BotoCoreError):
        return redact_text(str(exc)), "Check credentials, region and network access to AWS."
    return redact_text(f"{type(exc).__name__}: {exc}"), ""


class Test:
    """Runs steps in order. A failed prerequisite skips what depends on it, but never cleanup."""

    __test__ = False  # not a pytest class

    def __init__(self, provider: str, emit: Callable[[list[Step]], None]) -> None:
        self.provider, self.emit = provider, emit
        self.steps: list[Step] = []

    @property
    def passed(self) -> bool:
        return bool(self.steps) and all(s.status in {"passed", "skipped"} for s in self.steps)

    def step(
        self, key: str, en: str, sw: str, fn: Callable[[], str | None], *, needs: str | None = None
    ) -> bool:
        step = Step(key, en, sw, "running")
        self.steps.append(step)
        self.emit(self.steps)
        if needs and not any(s.key == needs and s.status == "passed" for s in self.steps):
            step.status, step.detail = "skipped", f"Skipped because '{needs}' did not pass."
        else:
            start = time.monotonic()
            try:
                step.detail = redact_text(fn() or "")
                step.status = "passed"
            except Exception as exc:  # every failure becomes a reported step
                step.status = "failed"
                step.detail, step.remediation = describe_error(exc)
            step.latency_ms = int((time.monotonic() - start) * 1000)
            log_call(self.provider, f"test.{key}", step.status == "passed", step.latency_ms, step.detail)
        self.emit(self.steps)
        return step.status == "passed"


class Provider[C: ProviderConfig](ABC):
    key: ClassVar[str]
    name: ClassVar[str]
    category: ClassVar[str]
    description_en: ClassVar[str]
    description_sw: ClassVar[str]
    schema_version: ClassVar[int] = 1
    config_model: type[C]
    test_params: ClassVar[list[str]] = []

    @abstractmethod
    def test(self, config: C, t: Test, params: dict[str, Any]) -> None: ...


_PROVIDERS: dict[str, Provider[Any]] = {}


def register_provider[T: type[Provider[Any]]](cls: T) -> T:
    _PROVIDERS[cls.key] = cls()
    return cls


def providers() -> dict[str, Provider[Any]]:
    return _PROVIDERS


def log_call(provider: str, operation: str, ok: bool, latency_ms: int, detail: str = "") -> None:
    from newsplatform.integrations.models import IntegrationCall

    try:
        with transaction.atomic():
            IntegrationCall.objects.create(
                provider=provider,
                operation=operation[:120],
                ok=ok,
                latency_ms=latency_ms,
                detail=redact_text(detail)[:2000],
                request_id=context.current().request_id,
            )
    except DatabaseError:
        log.exception("integration_call_log_failed", provider=provider)


_FAILS, _OPEN_FOR = 5, 30


@contextmanager
def guarded_call(provider: str, operation: str) -> Iterator[None]:
    """Circuit breaker plus call log around one outbound call."""
    key, open_key = f"cb:{{{provider}}}:fails", f"cb:{{{provider}}}:open"
    try:
        is_open = bool(cache().exists(open_key))
    except redis.RedisError:
        is_open = False
    if is_open:
        raise ServiceUnavailable(f"{provider} is temporarily unavailable", code="circuit_open")
    start = time.monotonic()
    try:
        yield
    except Exception as exc:
        log_call(provider, operation, False, int((time.monotonic() - start) * 1000), describe_error(exc)[0])
        try:
            fails = cache().incr(key)
            cache().expire(key, 60)
            if fails >= _FAILS:
                cache().set(open_key, 1, ex=_OPEN_FOR)
        except redis.RedisError:
            pass
        raise
    log_call(provider, operation, True, int((time.monotonic() - start) * 1000))
    with suppress(redis.RedisError):
        cache().delete(key)
