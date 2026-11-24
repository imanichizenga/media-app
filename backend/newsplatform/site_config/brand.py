"""The brand: name, logos, theme and colour, published as one version. ADR-0032."""

import hashlib
from typing import Any

from django.db import transaction
from django.db.models import Max
from pydantic import ValidationError

from newsplatform.accounts.models import User
from newsplatform.approvals import services as approvals
from newsplatform.approvals.models import ApprovalRequest, ApprovalStatus
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.rbac import selectors as rbac
from newsplatform.site_config import logos
from newsplatform.site_config.models import BrandLogo, BrandVersion, SettingsSection
from newsplatform.site_config.schemas import Appearance, Brand, Identity
from newsplatform.site_config.theme import derive as t

ACTION, PERMISSION = "brand.publish", "settings.manage"
_SLOTS = {"wordmark_light": "wordmark", "wordmark_dark": "wordmark", "symbol": "symbol"}
CSS_PREFIX = "/* The published theme. */\n"


# ---- reading ----
def tokens(look: Appearance) -> tuple[t.Tokens, t.Tokens]:
    return (
        t.derive(look.theme, "light", look.color, look.dark_color),
        t.derive(look.theme, "dark", look.color, look.dark_color),
    )


def css_of(look: Appearance) -> tuple[str, str]:
    css = CSS_PREFIX + t.stylesheet(*tokens(look))
    return hashlib.sha256(css.encode()).hexdigest()[:16], css


def stylesheet(digest: str) -> str | None:
    """By address. Old addresses keep working, so a page cached yesterday never loses its colours."""
    from newsplatform.site_config.services import get_brand

    found = BrandVersion.objects.filter(css_hash=digest).values_list("css", flat=True).first()
    if found is not None:
        return found
    current, css = css_of(get_brand()[0].appearance)  # before the first publication, or a new derivation
    return css if current == digest else None


def theme_body(look: Appearance) -> dict[str, Any]:
    light, dark = tokens(look)
    digest = css_of(look)[0]
    return {
        "schema_version": look.schema_version,
        "hash": digest,
        "key": look.theme,
        "color": look.color,
        "dark_color": look.dark_color,
        "css": f"/theme/{digest}.css",
        "theme_color": {"light": light["theme-color"], "dark": dark["theme-color"]},
        "tokens": {"light": light, "dark": dark},
    }


def identity_body(who: Identity) -> dict[str, Any]:
    ids = {n: getattr(who, n) for n in _SLOTS}
    found = {str(x.pk): x for x in BrandLogo.objects.filter(pk__in=[i for i in ids.values() if i])}
    light, dark = found.get(ids["wordmark_light"]), found.get(ids["wordmark_dark"])
    return {
        "brand_name": who.brand_name,
        "tagline_sw": who.tagline_sw,
        "tagline_en": who.tagline_en,
        "wordmark_light": logos.body(light),
        # On dark, the light wordmark in white, until there is one drawn for it.
        "wordmark_dark": logos.body(dark) if dark else logos.body(light, white=True),
        "symbol": logos.body(found.get(ids["symbol"])),
    }


def manifest(locale: str) -> dict[str, Any]:
    from newsplatform.site_config.services import get_brand

    brand = get_brand()[0]
    light = tokens(brand.appearance)[0]
    symbol = identity_body(brand.identity)["symbol"]
    icons = []
    if symbol:
        icons = [
            {"src": symbol["png"][n], "sizes": f"{s}x{s}", "type": "image/png", "purpose": "any"}
            for n, s in logos.SIZES.items()
        ]
        if symbol["svg"]:
            icons.append({"src": symbol["svg"], "sizes": "any", "type": "image/svg+xml", "purpose": "any"})
    return {
        "name": brand.identity.brand_name,
        "short_name": brand.identity.brand_name[:12],
        "description": brand.identity.tagline_en if locale == "en" else brand.identity.tagline_sw,
        "lang": locale,
        "start_url": "/en" if locale == "en" else "/",
        "display": "standalone",
        "background_color": light["bg"],
        "theme_color": light["theme-color"],
        "icons": icons,
    }


# ---- validity ----
def _failures(rows: list[t.Failure]) -> list[dict[str, Any]]:
    return [
        {
            "theme": f.theme,
            "scheme": f.scheme,
            "fg": f.fg,
            "bg": f.bg,
            "ratio": round(f.ratio, 2),
            "min": f.min,
        }
        for f in rows
    ]


def check_color(color: str, dark_color: str) -> None:
    """Refused with the pairs that fail, and the nearest colour that does not."""
    for which, bad in (
        ("color", t.failures(color)),
        ("dark_color", t.failures(color, dark_color, "dark") if dark_color else []),
    ):
        if bad:
            dark = which == "dark_color"
            raise DomainError(
                "This colour is not readable everywhere it is used.",
                code="contrast",
                field=which,
                nearest=t.nearest(color, dark_color, "dark") if dark else t.nearest(color),
                failures=_failures(bad),
            )


def _validate(data: dict[str, Any]) -> Brand:
    try:
        brand = Brand.model_validate(data)
    except ValidationError as exc:
        raise DomainError(
            "The settings are invalid.",
            code="validation_error",
            errors=[{"field": ".".join(map(str, e["loc"])), "message": e["msg"]} for e in exc.errors()],
        ) from exc
    check_color(brand.appearance.color, brand.appearance.dark_color)
    for slot, kind in _SLOTS.items():
        wanted = getattr(brand.identity, slot)
        if wanted and not BrandLogo.objects.filter(pk=wanted, kind=kind).exists():
            raise DomainError(
                "The settings are invalid.",
                code="validation_error",
                errors=[{"field": f"identity.{slot}", "message": "Upload this logo first"}],
            )
    return brand


# ---- publishing ----
def _flat(brand: dict[str, Any]) -> dict[str, Any]:
    return {f"{part}.{k}": v for part, values in brand.items() for k, v in values.items()}


def _write(
    *,
    actor: User,
    brand: Brand,
    version: int,
    note: str,
    restored_from: int | None,
    approved_by: User | None,
) -> int:
    SettingsSection.objects.get_or_create(key="brand", defaults={"version": 0, "data": {}})
    row = SettingsSection.objects.select_for_update().get(key="brand")
    if row.version != version:
        raise Conflict(
            "Someone else changed the brand. Reload and try again.", code="stale_version", current=row.version
        )
    before = _flat(Brand.model_validate(row.data).model_dump())
    clean = brand.model_dump()
    after = _flat(clean)
    # Rows written before history existed, or by the seed, carry no version of their own.
    number = max(row.version, BrandVersion.objects.aggregate(n=Max("number"))["n"] or 0) + 1
    row.data, row.version, row.updated_by = clean, number, actor
    row.save()
    digest, css = css_of(brand.appearance)
    BrandVersion.objects.create(
        number=number,
        data=clean,
        css_hash=digest,
        css=css,
        note=note,
        restored_from=restored_from,
        published_by=actor,
        approved_by=approved_by,
    )
    changed = sorted(k for k in after if before.get(k) != after[k])
    record(
        actor=actor,
        approved_by=approved_by,
        action="brand.restored" if restored_from else "brand.published",
        target=row,
        label=f"brand {number}",
        reason=note,
        before={k: before.get(k) for k in changed},
        after={k: after[k] for k in changed} | ({"restored_from": restored_from} if restored_from else {}),
    )

    def announce() -> None:
        from newsplatform.content.tasks import announce as send

        # Every page carries the stylesheet's address, so every page is told.
        send.delay(["brand"], [])

    transaction.on_commit(announce, robust=True)
    return number


@transaction.atomic
def publish(
    *, actor: User, data: dict[str, Any], version: int, note: str = "", restored_from: int | None = None
) -> int | ApprovalRequest:
    rbac.require(actor, PERMISSION)
    brand = _validate(data)
    if approvals.is_required(ACTION):
        return approvals.request_approval(
            actor=actor,
            action=ACTION,
            summary=f"Publish the brand: {brand.identity.brand_name}, {brand.appearance.theme}, "
            f"{brand.appearance.color}",
            payload={
                "data": brand.model_dump(),
                "version": version,
                "note": note,
                "restored_from": restored_from,
            },
            dedupe_key="brand",
            reason=note,
        )
    return _write(
        actor=actor, brand=brand, version=version, note=note, restored_from=restored_from, approved_by=None
    )


@approvals.register(ACTION, PERMISSION)
def _execute(payload: dict[str, Any], requester: User, approver: User) -> None:
    _write(
        actor=requester,
        brand=_validate(payload["data"]),
        version=payload["version"],
        note=payload["note"],
        restored_from=payload["restored_from"],
        approved_by=approver,
    )


def restore(*, actor: User, number: int, version: int) -> int | ApprovalRequest:
    """One click back: the old version is published again, as a new one."""
    old = BrandVersion.objects.filter(number=number).first()
    if old is None:
        raise NotFound("Not found")
    return publish(
        actor=actor, data=old.data, version=version, note=f"Version {number} restored", restored_from=number
    )


def waiting() -> ApprovalRequest | None:
    return ApprovalRequest.objects.filter(action=ACTION, status=ApprovalStatus.PENDING).first()
