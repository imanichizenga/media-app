import ipaddress
from typing import Any

from django.db import transaction
from pydantic import ValidationError

from newsplatform.accounts.models import User
from newsplatform.approvals import services as approvals
from newsplatform.approvals.models import ApprovalRequest
from newsplatform.audit.services import record
from newsplatform.common import context
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.rbac import selectors as rbac
from newsplatform.site_config.models import SettingsSection
from newsplatform.site_config.schemas import (
    SECTIONS,
    App,
    Brand,
    Identity,
    Localization,
    Section,
    Security,
    Seo,
)


def get_section(key: str) -> tuple[Section, int]:
    if key not in SECTIONS:
        raise NotFound("Unknown settings section")
    row = SettingsSection.objects.filter(key=key).first()
    return SECTIONS[key].model_validate(row.data if row else {}), row.version if row else 0


def get_security() -> Security:
    section = get_section("security")[0]
    assert isinstance(section, Security)  # noqa: S101 (type narrowing)
    return section


def get_brand() -> tuple[Brand, int]:
    section, version = get_section("brand")
    assert isinstance(section, Brand)  # noqa: S101 (type narrowing)
    return section, version


def identity() -> Identity:
    return get_brand()[0].identity


def brand_name() -> str:
    return identity().brand_name


def public_config() -> dict[str, Any]:
    from newsplatform.media.storage import base_url
    from newsplatform.site_config import brand

    config, v1 = get_brand()
    local, v2 = get_section("localization")
    seo, v3 = get_seo()
    app = get_app()[0]
    assert isinstance(local, Localization)  # noqa: S101
    return {
        "version": f"{v1}.{v2}.{v3}",
        "media_base_url": base_url(),
        "identity": brand.identity_body(config.identity),
        "theme": brand.theme_body(config.appearance),
        "localization": local.model_dump(),
        "seo": {
            "google_verification": seo.google_verification,
            "bing_verification": seo.bing_verification,
            "indexnow_key": seo.indexnow_key if seo.indexnow else "",
            "same_as": seo.same_as,
        },
        "engagement": {"card_counts": card_counts()},
        # Where the app is, for the banner on phones; empty until there is one to offer.
        "apps": {
            "android": app.store_android if seo.app_banner else "",
            "ios": app.store_ios if seo.app_banner else "",
        },
    }


def get_seo() -> tuple[Seo, int]:
    section, version = get_section("seo")
    assert isinstance(section, Seo)  # noqa: S101 (type narrowing)
    return section, version


_LINKS = ("about", "editorial", "corrections", "contact", "privacy", "terms")
_FLAGS = ("shorts", "youtube", "offline_saving")


def card_counts() -> bool:
    """Whether cards show views, likes and comments before a story is opened (Settings → Engagement)."""
    section = get_section("engagement")[0]
    return bool(getattr(section, "card_counts", True))


def get_app() -> tuple[App, int]:
    section, version = get_section("app")
    assert isinstance(section, App)  # noqa: S101 (type narrowing)
    return section, version


def app_config() -> dict[str, Any]:
    """Everything an installed app needs before it shows anything, in one answer."""
    app, version = get_app()
    site = public_config()
    return {
        "version": f"{site['version']}.{version}",
        "media_base_url": site["media_base_url"],
        "versions": {
            "android": {
                "minimum": app.min_android,
                "recommended": app.recommended_android,
                "store": app.store_android,
            },
            "ios": {"minimum": app.min_ios, "recommended": app.recommended_ios, "store": app.store_ios},
        },
        "maintenance": {"on": app.maintenance, "sw": app.maintenance_sw, "en": app.maintenance_en},
        "flags": {**{n: getattr(app, n) for n in _FLAGS}, "card_counts": card_counts()},
        "links": {n: getattr(app, f"link_{n}") for n in _LINKS},
        "pinning": {"enabled": app.pinning, "pins": app.pins if app.pinning else []},
        "identity": site["identity"],
        "theme": site["theme"],
        "localization": site["localization"],
    }


def asset_links() -> list[dict[str, Any]]:
    app = get_app()[0]
    return [
        {
            "relation": ["delegate_permission/common.handle_all_urls"],
            "target": {
                "namespace": "android_app",
                "package_name": package,
                "sha256_cert_fingerprints": app.android_certificates,
            },
        }
        for package in app.android_packages
        if app.android_certificates
    ]


def apple_links() -> dict[str, Any]:
    # Everything a reader opens; nothing of the website's own machinery.
    no = ("/api/*", "/theme/*", "/media/*", "/_next/*", "/healthz", "/monitoring")
    components = [*({"/": p, "exclude": True} for p in no), {"/": "/*"}]
    return {"applinks": {"details": [{"appIDs": get_app()[0].ios_app_ids, "components": components}]}}


def ip_allowed(ip: str | None, security: Security) -> bool:
    if not security.ip_allowlist_enabled:
        return True
    if not ip:
        return False
    addr = ipaddress.ip_address(ip)
    return any(addr in ipaddress.ip_network(n) for n in security.ip_allowlist)


def permission_for(key: str) -> str:
    # Readers' sign-in rules guard SMS spend and fraud limits: those who may change security may change them.
    return {
        "security": "settings.security",
        "sign_in": "settings.security",
        "engagement": "engagement.manage_policy",
    }.get(key, "settings.manage")


def _validate(key: str, data: dict[str, Any]) -> Section:
    try:
        return SECTIONS[key].model_validate(data)
    except ValidationError as exc:
        raise DomainError(
            "The settings are invalid.",
            code="validation_error",
            errors=[{"field": ".".join(map(str, e["loc"])), "message": e["msg"]} for e in exc.errors()],
        ) from exc


def _write(*, actor: User, key: str, data: dict[str, Any], version: int, approved_by: User | None) -> int:
    SettingsSection.objects.get_or_create(key=key, defaults={"version": 0, "data": {}})
    row = SettingsSection.objects.select_for_update().get(key=key)
    if row.version != version:
        raise Conflict(
            "Someone else changed these settings. Reload and try again.",
            code="stale_version",
            current=row.version,
        )
    before = SECTIONS[key].model_validate(row.data).model_dump()
    row.data, row.version, row.updated_by = data, row.version + 1, actor
    row.save()
    changed = {k for k in data if before.get(k) != data[k]}
    record(
        actor=actor,
        approved_by=approved_by,
        action="settings.updated",
        target=row,
        label=key,
        before={k: before.get(k) for k in changed},
        after={k: data[k] for k in changed},
    )
    if key in {"app", "seo", "engagement"}:
        from newsplatform.content.tasks import announce

        transaction.on_commit(lambda: announce.delay(["app-config", "site"], []), robust=True)
    if key == "security":
        from newsplatform.staff_security.tasks import sync_waf_allowlist

        transaction.on_commit(sync_waf_allowlist.delay)
    return row.version


@transaction.atomic
def update_section(
    *, actor: User, key: str, data: dict[str, Any], version: int, reason: str = ""
) -> int | ApprovalRequest:
    if key not in SECTIONS:
        raise NotFound("Unknown settings section")
    if key == "brand":
        raise DomainError("The brand is published on its own page.", code="use_appearance")
    rbac.require(actor, permission_for(key))
    section = _validate(key, data)
    clean = section.model_dump()
    if isinstance(section, Security):
        if not ip_allowed(context.current().ip, section):
            raise DomainError(
                "This would lock you out: your own address is not in the list.",
                code="self_lockout",
                ip=context.current().ip,
            )
        # Judged by the policy in force now, so turning four-eyes off itself needs four eyes.
        if approvals.is_required("settings.security"):
            return approvals.request_approval(
                actor=actor,
                action="settings.security",
                summary="Change security settings",
                payload={"data": clean, "version": version},
                dedupe_key="security",
                reason=reason,
            )
    trust = isinstance(section, App) and _sensitive(section) != _sensitive(get_app()[0])
    if trust and approvals.is_required("settings.app_trust"):
        return approvals.request_approval(
            actor=actor,
            action="settings.app_trust",
            summary="Change what installed apps trust: pins, links or the oldest version allowed",
            payload={"data": clean, "version": version},
            dedupe_key="app_trust",
            reason=reason,
        )
    return _write(actor=actor, key=key, data=clean, version=version, approved_by=None)


def _sensitive(app: App) -> dict[str, Any]:
    """A mistake here locks every phone out, or lets another app open our links."""
    names = (
        "pinning",
        "pins",
        "android_packages",
        "android_certificates",
        "ios_app_ids",
        "min_android",
        "min_ios",
    )
    return {n: getattr(app, n) for n in names}


@approvals.register("settings.app_trust", "settings.manage")
def _execute_app(payload: dict[str, Any], requester: User, approver: User) -> None:
    _write(
        actor=requester,
        key="app",
        data=_validate("app", payload["data"]).model_dump(),
        version=payload["version"],
        approved_by=approver,
    )


@approvals.register("settings.security", "settings.security")
def _execute(payload: dict[str, Any], requester: User, approver: User) -> None:
    section = _validate("security", payload["data"])
    assert isinstance(section, Security)  # noqa: S101
    if not ip_allowed(context.current().ip, section):
        raise DomainError(
            "This would lock you out: your own address is not in the list.", code="self_lockout"
        )
    _write(
        actor=requester,
        key="security",
        data=section.model_dump(),
        version=payload["version"],
        approved_by=approver,
    )
