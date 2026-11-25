from typing import Any

from django.db import transaction
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.errors import Conflict, DomainError, NotFound
from newsplatform.common.locales import Locale
from newsplatform.content import blocks
from newsplatform.media.models import Asset, AssetStatus
from newsplatform.media.presenters import image, video
from newsplatform.pages.models import Page, PageKey, PageRevision
from newsplatform.rbac import selectors as rbac
from newsplatform.seo import paths

PERM = "pages.manage"


def get(key: str) -> Page:
    if key not in PageKey.values:
        raise NotFound("Not found")
    return Page.objects.select_related("published").filter(key=key).first() or Page(key=key)


def _lock(key: str) -> Page:
    if key not in PageKey.values:
        raise NotFound("Not found")
    Page.objects.get_or_create(key=key)
    return Page.objects.select_for_update().get(key=key)


def _clean(texts: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    if set(texts) - set(Locale.values):
        raise DomainError("Unknown language", code="validation_error")
    out = {}
    for locale, text in texts.items():
        title = str(text.get("title", "")).strip()[:120]
        summary = str(text.get("summary", "")).strip()[:300]
        body = blocks.validate(text.get("body") or {"version": 1, "blocks": []})
        if title or summary or body["blocks"]:
            out[locale] = {"title": title, "summary": summary, "body": body}
    return out


@transaction.atomic
def save(
    *, actor: User, key: str, version: int, texts: dict[str, dict[str, Any]], note: str = ""
) -> PageRevision:
    rbac.require(actor, PERM)
    page = _lock(key)
    if page.version != version:
        raise Conflict(
            "Someone else changed this. Reload and try again.", code="stale_version", current=page.version
        )
    page.version += 1
    page.save(update_fields=["version", "updated_at"])
    row = PageRevision.objects.create(
        page=page, number=page.version, texts=_clean(texts), note=note[:300], author=actor
    )
    record(actor=actor, action="page.saved", target=page, label=key, after={"revision": row.number})
    return row


def problems(revision: PageRevision) -> list[str]:
    missing = [
        f"{locale}.{field}"
        for locale in Locale.values
        for field in ("title", "body")
        if not (revision.texts.get(locale, {}).get(field) or {}) or _blank(revision, locale, field)
    ]
    used = Asset.objects.filter(pk__in=_assets(revision))
    if any(a.status != AssetStatus.READY for a in used):
        missing.append("media")
    return missing


def _blank(revision: PageRevision, locale: str, field: str) -> bool:
    value = revision.texts[locale][field]
    return not value["blocks"] if field == "body" else not value


def _assets(revision: PageRevision) -> set[Any]:
    return {i for t in revision.texts.values() for i in blocks.asset_ids(t["body"])}


@transaction.atomic
def publish(*, actor: User, key: str, number: int) -> Page:
    """Any revision, so going back is publishing an older one. Both languages, always: a promise made in one
    language is not a promise to the other's readers."""
    rbac.require(actor, PERM)
    page = _lock(key)
    row = page.revisions.filter(number=number).first()
    if row is None:
        raise NotFound("Not found")
    if missing := problems(row):
        raise DomainError("This is not ready to publish.", code="not_ready", missing=missing)
    before = page.published.number if page.published else None
    page.published, page.published_at = row, timezone.now()
    page.first_published_at = page.first_published_at or page.published_at
    page.save(update_fields=["published", "published_at", "first_published_at", "updated_at"])
    record(
        actor=actor,
        action="page.published",
        target=page,
        label=key,
        before={"revision": before},
        after={"revision": row.number},
    )
    _changed(page)
    return page


@transaction.atomic
def withdraw(*, actor: User, key: str) -> Page:
    rbac.require(actor, PERM)
    page = _lock(key)
    before = page.published.number if page.published else None
    page.published = page.published_at = None
    page.save(update_fields=["published", "published_at", "updated_at"])
    record(actor=actor, action="page.withdrawn", target=page, label=key, before={"revision": before})
    _changed(page)
    return page


def _changed(page: Page) -> None:
    from newsplatform.content.tasks import announce

    pages = [paths.page_path(locale, page.key) for locale in Locale.values]
    # The footer of every page lists what exists.
    transaction.on_commit(lambda: announce.delay(["pages", f"page-{page.key}"], pages), robust=True)


# ---- readers ------------------------------------------------------------
def listed(locale: str) -> list[dict[str, Any]]:
    rows = Page.objects.filter(published__isnull=False).select_related("published")
    order = {k: i for i, k in enumerate(PageKey.values)}
    return [
        {
            "key": p.key,
            "title": p.published.texts[locale]["title"],
            "path": paths.page_path(locale, p.key),
            "modified_at": p.published_at,
        }
        for p in sorted(rows, key=lambda p: order[p.key])
        if p.published
    ]


def public(locale: str, key: str) -> dict[str, Any]:
    page = get(key)
    if page.published is None:
        raise NotFound("Not found")
    text = page.published.texts[locale]
    assets = Asset.objects.filter(pk__in=blocks.asset_ids(text["body"]))
    return {
        "key": key,
        "locale": locale,
        "path": paths.page_path(locale, key),
        "title": text["title"],
        "summary": text["summary"],
        "body": text["body"],
        "assets": {str(a.pk): image(a, locale) if a.kind == "image" else video(a, locale) for a in assets},
        "published_at": page.first_published_at,
        "modified_at": page.published_at,
        "translations": [
            {"locale": other, "path": paths.page_path(other, key)}
            for other in Locale.values
            if other != locale
        ],
    }
