"""Reads. Editors see the working copy through permissions; readers see only Publication."""

import base64
import binascii
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from django.db.models import Q, QuerySet
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.common.errors import DomainError, NotFound
from newsplatform.content.models import Feed, Listing, Post, PostType, Publication
from newsplatform.rbac import selectors as rbac

PAGE = 20


# ---- editors ------------------------------------------------------------
def visible_posts(user: User) -> QuerySet[Post]:
    """The same rule as services.can_view, as one query."""
    grants = rbac.grants_for(user)
    wide = {"content.edit_others", "content.review", "content.publish"}
    if wide & grants.everywhere:
        return Post.objects.all()
    mine = Q(created_by=user) | Q(bylines__user=user)
    branches = [
        UUID(ident) for (kind, ident), perms in grants.scoped.items() if kind == "category" and perms & wide
    ]
    if branches:
        mine |= Q(category_id__in=branches) | Q(category__ancestors__overlap=branches)
    return Post.objects.filter(pk__in=Post.objects.filter(mine).values("pk"))


# ---- readers ------------------------------------------------------------
def encode(row: Listing) -> str:
    raw = f"{row.published_at.astimezone(UTC).isoformat()}|{row.publication_id}"
    return base64.urlsafe_b64encode(raw.encode()).decode().rstrip("=")


def decode(cursor: str) -> tuple[datetime, UUID]:
    try:
        raw = base64.urlsafe_b64decode(cursor + "=" * (-len(cursor) % 4)).decode()
        stamp, _, ident = raw.partition("|")
        at = datetime.fromisoformat(stamp)
        if at.tzinfo is None:
            raise ValueError(stamp)
        return at, UUID(ident)
    except (ValueError, binascii.Error) as exc:
        raise DomainError("Invalid cursor", code="invalid_cursor") from exc


def feed(
    locale: str, kind: str, key: str = "", *, cursor: str = "", limit: int = PAGE
) -> tuple[list[dict[str, Any]], str | None]:
    """One index range scan and one join, at any depth."""
    rows = Listing.objects.filter(locale=locale, feed=kind, key=key)
    if cursor:
        at, ident = decode(cursor)
        rows = rows.filter(Q(published_at__lt=at) | Q(published_at=at, publication_id__lt=ident))
    found = list(
        rows.select_related("publication")
        .only("published_at", "publication_id", "publication__card", "publication__modified_at")
        .order_by("-published_at", "-publication_id")[: limit + 1]
    )
    page = found[:limit]
    return [card(r.publication) for r in page], encode(page[-1]) if len(found) > limit else None


def card(row: Publication) -> dict[str, Any]:
    return {**current(row.card), "modified_at": row.modified_at.isoformat()}


def current(shape: dict[str, Any]) -> dict[str, Any]:
    """A card or article published before a field was added gets it here, until it is published again."""
    if "rail_title" in shape and "short_name" in shape["category"] and "premium" in shape:
        return shape
    from newsplatform.content.publishing import rail_title

    def short(category: dict[str, Any]) -> dict[str, Any]:
        return {**category, "short_name": category.get("short_name") or category["name"]}

    upgraded = {
        **shape,
        "rail_title": shape.get("rail_title") or rail_title(shape["headline"]),
        "category": short(shape["category"]),
        "premium": bool(shape.get("premium", False)),
    }
    if "breadcrumbs" in shape:
        upgraded["breadcrumbs"] = [short(c) for c in shape["breadcrumbs"]]
    return upgraded


def several(locale: str, wanted: list[tuple[str, str, int]]) -> list[list[dict[str, Any]]]:
    """Many short feeds in two queries, however many there are."""
    if not wanted:
        return []
    parts = [
        Listing.objects.filter(locale=locale, feed=kind, key=key)
        .order_by("-published_at", "-publication_id")
        .values_list("feed", "key", "publication_id", "published_at")[:limit]
        for kind, key, limit in wanted
    ]
    rows = parts[0].union(*parts[1:], all=True) if len(parts) > 1 else parts[0]
    found = sorted(rows, key=lambda r: (r[3], r[2]), reverse=True)
    cards = {
        p.pk: card(p)
        for p in Publication.objects.filter(pk__in={r[2] for r in found}).only("card", "modified_at")
    }
    return [[cards[r[2]] for r in found if (r[0], r[1]) == (kind, key)] for kind, key, _ in wanted]


def breaking(locale: str, limit: int = 3) -> list[dict[str, Any]]:
    rows = Publication.objects.filter(locale=locale, breaking_until__gt=timezone.now())
    return [card(p) for p in rows.only("card", "modified_at").order_by("-published_at")[:limit]]


def live(locale: str, limit: int = 10) -> list[dict[str, Any]]:
    rows = Publication.objects.filter(locale=locale, is_live=True)
    return [card(p) for p in rows.only("card", "modified_at").order_by("-published_at")[:limit]]


def article(locale: str, slug: str) -> Publication:
    row = Publication.objects.filter(locale=locale, slug=slug).defer("card").first()
    if row is None:
        raise NotFound("Not found")
    return row


def related(row: Publication, limit: int = 8) -> list[dict[str, Any]]:
    """The same ongoing story first, then shared tags, then the section (search takes over in M8)."""
    mine = list(Listing.objects.filter(publication=row).values_list("feed", "key"))
    by_kind = [(Feed.STORY, limit), (Feed.TAG, limit), (Feed.CATEGORY, limit)]
    wanted = [(str(kind), k, n) for kind, n in by_kind for f, k in mine if f == kind]
    seen, out = {str(row.post_id)}, []
    for found in several(row.locale, wanted):
        for item in found:
            if item["id"] not in seen and item["type"] != PostType.SHORT:
                seen.add(item["id"])
                out.append(item)
    return out[:limit]
