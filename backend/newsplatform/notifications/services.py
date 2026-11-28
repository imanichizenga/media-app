"""Telling readers' browsers of new stories (Web Push). Anyone may subscribe; the newsroom's switch is in
Settings → Engagement ("Notify readers of each new story")."""

from __future__ import annotations

import json
import logging
from typing import Any

import httpx
from django.conf import settings
from django.db import transaction

from newsplatform.common.crypto import decrypt, encrypt
from newsplatform.common.errors import DomainError
from newsplatform.notifications import webpush
from newsplatform.notifications.models import Notice, NoticeKind, PushKey, PushSubscription

log = logging.getLogger(__name__)
CTX = {"purpose": "web-push-vapid"}
TTL = 6 * 3600  # a story older than this is not news on a lock screen
GIVE_UP = 5  # failures in a row before a subscription is dropped


def keys() -> tuple[str, bytes]:
    """(public, private DER), made the first time they are asked for."""
    with transaction.atomic():
        row = PushKey.objects.select_for_update().first()
        if row is None:
            public, private = webpush.new_key()
            row = PushKey.objects.create(public=public, private=encrypt(private, CTX))
    return row.public, decrypt(row.private, CTX)


def enabled_push() -> bool:
    """Push can be sent at all: the site has said who it is to push services."""
    return bool(settings.WEB_PUSH_SUBJECT)


def enabled() -> bool:
    """Every new story is pushed too (Settings → Engagement), not only the bell's notices."""
    from newsplatform.site_config.services import get_section

    section = get_section("engagement")[0]
    return enabled_push() and bool(getattr(section, "push_new_stories", True))


def subscribe(data: dict[str, Any], user: Any = None) -> PushSubscription:
    endpoint = str(data.get("endpoint") or "")
    found = data.get("keys")
    sealed = found if isinstance(found, dict) else {}
    p256dh, auth = str(sealed.get("p256dh") or ""), str(sealed.get("auth") or "")
    if not webpush.allowed(endpoint) or len(endpoint) > 1000:
        raise DomainError("This is not a push service.", code="validation_error", field="endpoint")
    try:
        if len(webpush.unb64u(p256dh)) != 65 or len(webpush.unb64u(auth)) != 16:
            raise ValueError
    except ValueError as exc:
        raise DomainError("These are not a browser's keys.", code="validation_error", field="keys") from exc
    locale = "en" if data.get("locale") == "en" else "sw"
    row, _ = PushSubscription.objects.update_or_create(
        endpoint=endpoint,
        defaults={"p256dh": p256dh, "auth": auth, "locale": locale, "user": user, "failures": 0},
    )
    return row


def unsubscribe(endpoint: str) -> None:
    PushSubscription.objects.filter(endpoint=str(endpoint or "")).delete()


def message(post_id: str, locale: str) -> dict[str, Any] | None:
    """What the lock screen says: the brand, the headline, the picture; a tap opens the story."""
    from newsplatform.content.models import Publication
    from newsplatform.site_config.services import public_config

    row = Publication.objects.filter(post_id=post_id, locale=locale).first()
    if row is None:
        return None
    site = public_config()
    picture = row.card.get("image") if isinstance(row.card.get("image"), dict) else {}
    widths = [w for w in picture.get("widths") or [] if isinstance(w, int)]
    width = min(widths, key=lambda w: abs(w - 800)) if widths else None
    image = f"{picture.get('base', '')}{width}.jpg" if width and picture.get("base") else None
    return {
        "title": site["identity"].get("brand_name") or "News",
        "body": row.card.get("headline", ""),
        "url": row.path,
        "tag": f"post-{post_id}",
        "image": f"{site['media_base_url']}{image}" if image else "",
    }


def send(row: PushSubscription, payload: dict[str, Any], client: httpx.Client) -> webpush.Outcome:
    public, private = keys()
    body = webpush.encrypt(json.dumps(payload, ensure_ascii=False).encode(), row.p256dh, row.auth)
    try:
        res = client.post(
            row.endpoint,
            content=body,
            headers={
                "Authorization": webpush.vapid(row.endpoint, private, public, settings.WEB_PUSH_SUBJECT),
                "Content-Encoding": "aes128gcm",
                "Content-Type": "application/octet-stream",
                "TTL": str(TTL),
                "Urgency": "normal",
            },
        )
    except httpx.HTTPError:
        return webpush.Outcome(ok=False, gone=False)
    if res.status_code in (404, 410):
        return webpush.Outcome(ok=False, gone=True)
    return webpush.Outcome(ok=res.status_code < 300, gone=False)


def send_batch(ids: list[str], payload: dict[str, Any]) -> int:
    sent = 0
    with httpx.Client(timeout=10, follow_redirects=False) as client:
        for row in PushSubscription.objects.filter(pk__in=ids):
            outcome = send(row, payload, client)
            if outcome.gone or (not outcome.ok and row.failures + 1 >= GIVE_UP):
                row.delete()
            elif not outcome.ok:
                PushSubscription.objects.filter(pk=row.pk).update(failures=row.failures + 1)
            else:
                sent += 1
                if row.failures:
                    PushSubscription.objects.filter(pk=row.pk).update(failures=0)
    return sent


# ---- the bell's list (ADR-0051) ----
SHOWN_DAYS = 7
SHOWN = 30


def body_of(row: Notice) -> dict[str, Any]:
    return {
        "id": str(row.pk),
        "kind": row.kind,
        "title": row.title,
        "body": row.body,
        "url": row.url,
        "image": row.image,
        "created_at": row.created_at.isoformat(),
    }


def recent(locale: str) -> list[dict[str, Any]]:
    from datetime import timedelta

    from django.utils import timezone

    since = timezone.now() - timedelta(days=SHOWN_DAYS)
    rows = Notice.objects.filter(locale=locale, created_at__gte=since).order_by("-created_at")[:SHOWN]
    return [body_of(r) for r in rows]


def _announce(rows: list[Notice]) -> None:
    """Each language's row goes to that language's devices, after commit."""
    from newsplatform.notifications.tasks import notice_pushed

    ids = [str(r.pk) for r in rows]
    transaction.on_commit(lambda: [notice_pushed.delay(i) for i in ids], robust=True)


def from_post(post_id: str, kind: str, actor: Any = None) -> list[Notice]:
    """A published story in the bell, in each language it has."""
    from newsplatform.content.models import Publication

    rows = []
    for pub in Publication.objects.filter(post_id=post_id):
        said = message(str(post_id), pub.locale) or {}
        rows.append(
            Notice.objects.create(
                kind=kind,
                locale=pub.locale,
                title=pub.card.get("headline", "")[:140],
                body=(pub.card.get("standfirst") or "")[:300],
                url=pub.path,
                image=said.get("image", ""),
                post_id=post_id,
                created_by=actor,
            )
        )
    _announce(rows)
    return rows


def first_published(post: Any) -> None:
    """Live coverage and breaking news go in the bell by themselves, once."""
    from django.utils import timezone

    if post.is_live if hasattr(post, "is_live") else False:
        from_post(str(post.pk), NoticeKind.LIVE)
    elif post.breaking_until and post.breaking_until > timezone.now():
        from_post(str(post.pk), NoticeKind.BREAKING)


def send_notice(actor: Any, data: dict[str, Any]) -> list[Notice]:
    """From the newsroom: a story (by its address on the site), or a few words of its own in each language."""
    from newsplatform.content.models import Publication

    link = str(data.get("url") or "").strip()
    if link:
        from urllib.parse import urlsplit

        path = urlsplit(link).path or "/"
        pub = Publication.objects.filter(path=path).first()
        if pub is not None and not any(str(data.get(f"title_{x}") or "").strip() for x in ("sw", "en")):
            return from_post(str(pub.post_id), NoticeKind.STORY, actor)
        if not path.startswith("/") or path.startswith("//"):
            raise DomainError("A link is an address on this site.", code="validation_error", field="url")
        link = path
    rows = []
    for locale in ("sw", "en"):
        title = " ".join(str(data.get(f"title_{locale}") or "").split())[:140]
        if not title:
            continue
        body = " ".join(str(data.get(f"body_{locale}") or "").split())[:300]
        rows.append(
            Notice.objects.create(
                kind=NoticeKind.NOTICE, locale=locale, title=title, body=body, url=link, created_by=actor
            )
        )
    if not rows:
        raise DomainError(
            "Write a title, or give the address of a story.", code="validation_error", field="title_sw"
        )
    _announce(rows)
    return rows
