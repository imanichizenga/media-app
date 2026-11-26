"""Builds what readers get. The only writer of Publication and Listing (ADR-0023)."""

import hashlib
from datetime import datetime
from typing import Any
from uuid import UUID

from django.db import transaction
from django.utils import timezone

from newsplatform.common.canonical import canonical_json
from newsplatform.common.errors import DomainError, NotFound
from newsplatform.content import blocks
from newsplatform.content.authors import byline, named
from newsplatform.content.authors import ensure as author_profile
from newsplatform.content.models import Feed, Listing, Post, PostText, PostType, Publication, RevisionKind
from newsplatform.engagement.services import resolved
from newsplatform.media.models import Asset, AssetStatus
from newsplatform.media.presenters import image, video
from newsplatform.search import vectors
from newsplatform.seo import paths
from newsplatform.seo.services import moved
from newsplatform.taxonomy.models import Visibility
from newsplatform.taxonomy.selectors import policy_chain, tree

_NEEDS_VIDEO = {PostType.VIDEO, PostType.SHORT}
_LIVE = {PostType.LIVE_BLOG, PostType.LIVE_STREAM}


def ready_texts(post: Post) -> list[PostText]:
    """Languages with something to publish. A started translation without a headline waits."""
    return [t for t in post.texts.order_by("locale") if t.headline]


def check_ready(post: Post) -> None:
    if missing := problems(post):
        raise DomainError("This is not ready to publish.", code="not_ready", missing=missing)


def problems(post: Post) -> list[str]:
    """What stands between this post and publication; the editor shows it before anyone tries."""
    missing: list[str] = []
    texts = ready_texts(post)
    if not texts:
        missing.append("headline")
    if post.category.visibility == Visibility.ARCHIVED:
        missing.append("category")
    if not post.bylines.exists():
        missing.append("author")
    if post.type in _NEEDS_VIDEO and not post.video_id:
        missing.append("video")
    if post.type == PostType.YOUTUBE and not post.youtube_id:
        missing.append("youtube")
    if post.type == PostType.YOUTUBE and not post.youtube_seconds:
        missing.append("duration")
    if post.type in {PostType.ARTICLE, PostType.OPINION} and not any(t.body["blocks"] for t in texts):
        missing.append("body")
    ids = {i for t in texts for i in blocks.asset_ids(t.body)} | {
        i for i in (post.hero_id, post.video_id) if i
    }
    used = list(Asset.objects.filter(pk__in=ids))
    if any(a.status != AssetStatus.READY for a in used):
        missing.append("media")
    if any(a.kind == "image" and not a.credit for a in used):
        missing.append("credit")
    hero = next((a for a in used if a.pk == post.hero_id), None)
    if hero and not all(getattr(hero, f"alt_{t.locale}") for t in texts):
        missing.append("alt")
    return missing


@transaction.atomic
def publish(post: Post) -> list[Publication]:
    texts = ready_texts(post)
    _assign_slugs(post, texts)
    nodes = tree()
    context = _context(post, texts, nodes)
    rows = [_write(post, text, context) for text in texts]
    _link_translations(rows)
    gone = list(post.publications.exclude(locale__in=[t.locale for t in texts]))
    for row in gone:
        row.delete()
    changed(post, [*rows, *gone])
    return rows


@transaction.atomic
def refresh(post: Post) -> None:
    """Rebuilds around the text readers already have. Unpublished edits stay unpublished."""
    published = post.revisions.filter(kind=RevisionKind.PUBLISH).first()
    if published is None:
        return
    snap = published.snapshot
    live = Post.objects.get(pk=post.pk)
    for name in ("hero_id", "video_id"):
        setattr(live, name, UUID(snap[name[:-3]]) if snap[name[:-3]] else None)
    for name in ("youtube_id", "source_url", "is_sensitive", "content_warning", "engagement"):
        setattr(live, name, snap[name])
    live.youtube_seconds = snap.get("youtube_seconds", 0)  # older revisions have none
    for name in ("breaking_until", "live_ended_at"):
        setattr(live, name, datetime.fromisoformat(snap[name]) if snap.get(name) else None)
    texts = [
        PostText(post=live, locale=loc, **values)
        for loc, values in snap["texts"].items()
        if values["headline"]
    ]
    for text in texts:
        # Slugs may have been assigned while publishing.
        row = post.publications.filter(locale=text.locale).first()
        text.slug = row.slug if row else text.slug
    texts = [t for t in texts if post.publications.filter(locale=t.locale).exists()]
    context = _context(live, texts, tree())
    rows = [_write(live, text, context) for text in texts]
    _link_translations(rows)
    changed(live, rows)


def _assign_slugs(post: Post, texts: list[PostText]) -> None:
    for text in texts:
        if text.slug:
            continue
        base = paths.slugify(text.headline) or "habari"
        taken = PostText.objects.filter(locale=text.locale, slug=base).exclude(pk=text.pk).exists()
        # The last block of a UUIDv7 is random, so two posts with one headline differ.
        text.slug = f"{base}-{post.pk.hex[-6:]}" if taken else base
        text.save(update_fields=["slug", "updated_at"])


def _context(
    post: Post, texts: list[PostText], nodes: dict[UUID, Any], *, writing: bool = True
) -> dict[str, Any]:
    ids = {i for t in texts for i in blocks.asset_ids(t.body)} | {
        i for i in (post.hero_id, post.video_id) if i
    }
    node = nodes[post.category_id]
    return {
        "nodes": nodes,
        "node": node,
        "assets": {a.pk: a for a in Asset.objects.filter(pk__in=ids)},
        "authors": [
            author_profile(b.user, save=writing)
            for b in post.bylines.select_related("user__author__avatar").order_by("position")
        ],
        "tags": list(post.tags.filter(merged_into__isnull=True).order_by("slug")),
        "regions": list(post.regions.order_by("slug")),
        "secondary": list(post.secondary_categories.all()),
        "engagement": resolved([*policy_chain(node.category), post.engagement]).model_dump(mode="json"),
    }


def _category(node: Any, locale: str) -> dict[str, Any]:
    return {
        "id": str(node.category.pk),
        "name": node.name(locale),
        "short_name": node.short_name(locale),
        "slug": node.slug(locale),
        "path": paths.category_path(locale, node.slug(locale)),
        "color": node.category.color,
    }


def build(
    post: Post, text: PostText, ctx: dict[str, Any], path: str
) -> tuple[dict[str, Any], dict[str, Any]]:
    """The card and the article, exactly as readers get them. Writes nothing, so previews use it too."""
    locale = text.locale
    node, assets = ctx["node"], ctx["assets"]
    hero = assets.get(post.hero_id)
    clip = assets.get(post.video_id)
    card = {
        "id": str(post.pk),
        "type": post.type,
        "locale": locale,
        "path": path,
        "slug": text.slug,
        "headline": text.headline,
        "rail_title": text.rail_title or rail_title(text.headline),
        "standfirst": text.standfirst,
        "category": _category(node, locale),
        "authors": [named(a, locale) for a in ctx["authors"]],
        "image": image(hero, locale) if hero else None,
        "video": video(clip, locale) if clip else None,
        "youtube_id": post.youtube_id,
        "duration_ms": clip.duration_ms if clip else post.youtube_seconds * 1000 or None,
        "reading_minutes": blocks.reading_minutes(text.body),
        "published_at": _iso(post.published_at),
        "is_sensitive": post.is_sensitive,
        "breaking_until": _iso(post.breaking_until),
        "is_live": is_live(post),
    }
    name = "name_en" if locale == "en" else "name_sw"
    article = {
        **card,
        "authors": [byline(a, locale) for a in ctx["authors"]],
        "body": text.body,
        "assets": {str(i): _asset(assets[i], locale) for i in blocks.asset_ids(text.body) if i in assets},
        "links": _links(text),
        "breadcrumbs": [
            _category(ctx["nodes"][a], locale) for a in node.category.ancestors if a in ctx["nodes"]
        ],
        "tags": [
            {"slug": t.slug, "name": getattr(t, name), "path": paths.tag_path(locale, t.slug)}
            for t in ctx["tags"]
        ],
        "regions": [{"slug": r.slug, "name": getattr(r, name)} for r in ctx["regions"]],
        "story": _story(post, locale),
        "engagement": ctx["engagement"],
        "content_warning": post.content_warning,
        "source_url": post.source_url,
        "update_note": text.update_note,
        "correction_note": text.correction_note,
        "seo": {
            "title": text.seo_title or text.headline,
            "description": text.seo_description or text.standfirst,
        },
        "first_published_at": _iso(post.first_published_at),
        "live_ended_at": _iso(post.live_ended_at),
        "translations": [],
    }
    return card, article


def _links(text: PostText) -> dict[str, dict[str, str]]:
    """Where related-link blocks point. A post that is not public is absent: no dead links."""
    ids = {b["post"] for _, b in blocks.walk(text.body) if b["type"] == "related_link" and b.get("post")}
    rows = Publication.objects.filter(post_id__in=ids, locale=text.locale) if ids else []
    return {str(r.post_id): {"path": r.path, "headline": r.card["headline"]} for r in rows}


RAIL_TITLE = 24


def rail_title(headline: str) -> str:
    """The headline cut between words to the rail's length, never inside one (unless the first is longer)."""
    if len(headline) <= RAIL_TITLE:
        return headline
    words, kept = headline.split(), ""
    for word in words:
        joined = f"{kept} {word}" if kept else word
        if len(joined) + 1 > RAIL_TITLE:
            break
        kept = joined
    kept = kept.rstrip(" ,.;:\u2013\u2014-") or headline[: RAIL_TITLE - 1].rstrip()
    return f"{kept}…"


def is_live(post: Post) -> bool:
    return post.type in _LIVE and post.live_ended_at is None


def preview(post: Post, locale: str) -> dict[str, Any]:
    """The working copy as a reader would see it. Nothing is stored and no address is taken."""
    text = post.texts.filter(locale=locale).first()
    if text is None:
        raise NotFound("Not found")
    nodes = tree()
    ctx = _context(post, [text], nodes, writing=False)
    slug = text.slug or paths.slugify(text.headline) or "habari"
    _, article = build(post, text, ctx, paths.post_path(locale, ctx["node"].slug(locale), slug))
    return {**article, "modified_at": _iso(timezone.now())}


def _write(post: Post, text: PostText, ctx: dict[str, Any]) -> Publication:
    locale = text.locale
    path = paths.post_path(locale, ctx["node"].slug(locale), text.slug)
    card, article = build(post, text, ctx, path)
    previous = post.publications.filter(locale=locale).first()
    modified = timezone.now()
    if post.published_at is None:  # the database enforces this too
        raise RuntimeError("A post without a publication time cannot be published")
    digest = hashlib.sha256(canonical_json([card, article])).hexdigest()
    if previous and previous.etag == digest:
        modified = previous.modified_at  # rebuilt, not changed: "updated" must not move
    row, _ = Publication.objects.update_or_create(
        post=post,
        locale=locale,
        defaults={
            "path": path,
            "slug": text.slug,
            "type": post.type,
            "category": post.category,
            "published_at": post.published_at,
            "modified_at": modified,
            "breaking_until": post.breaking_until,
            "is_live": is_live(post),
            "card": card,
            "article": article,
            "etag": digest,
            "asset_ids": sorted(ctx["assets"]),
        },
    )
    if previous and previous.path != path:
        moved(previous.path, path)
    _relist(row, post, ctx)
    vectors.write(
        [row]
    )  # in this transaction: Postgres's search is right even if the queue is not (ADR-0049)
    return row


def _asset(asset: Asset, locale: str) -> dict[str, Any]:
    return image(asset, locale) if asset.kind == "image" else video(asset, locale)


def _iso(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def _story(post: Post, locale: str) -> dict[str, Any] | None:
    if post.story is None:
        return None
    title = post.story.title_en if locale == "en" else post.story.title_sw
    return {"slug": post.story.slug, "title": title, "path": paths.story_path(locale, post.story.slug)}


def _relist(row: Publication, post: Post, ctx: dict[str, Any]) -> None:
    sections = {post.category_id, *ctx["node"].category.ancestors}
    for extra in ctx["secondary"]:
        sections |= {extra.pk, *extra.ancestors}
    feeds = [(Feed.ALL, ""), (Feed.TYPE, post.type)]
    feeds += [(Feed.CATEGORY, str(c)) for c in sections]
    feeds += [(Feed.TAG, str(t.pk)) for t in ctx["tags"]]
    feeds += [(Feed.AUTHOR, str(a.user_id)) for a in ctx["authors"]]
    if post.story_id:
        feeds.append((Feed.STORY, str(post.story_id)))
    Listing.objects.filter(publication=row).delete()
    Listing.objects.bulk_create(
        Listing(publication=row, locale=row.locale, feed=f, key=k, published_at=row.published_at)
        for f, k in feeds
    )


def _link_translations(rows: list[Publication]) -> None:
    links = [{"locale": r.locale, "path": r.path} for r in rows]
    for row in rows:
        row.article["translations"] = [t for t in links if t["locale"] != row.locale]
        row.save(update_fields=["article", "updated_at"])


@transaction.atomic
def withdraw(post: Post) -> None:
    rows = list(post.publications.all())
    for row in rows:
        row.delete()
    changed(post, rows)


def changed(post: Post, rows: list[Publication]) -> None:
    """Tells the CDN and the website, after commit."""
    from newsplatform.content.tasks import announce
    from newsplatform.search.tasks import index_post

    tags = sorted(
        {f"post-{post.pk}", f"category-{post.category_id}", "latest"}
        | {f"author-{b.user_id}" for b in post.bylines.all()}
        | {f"tag-{t}" for t in post.tags.values_list("slug", flat=True)}
        | ({f"story-{post.story.slug}"} if post.story else set())
        | {f"category-{a}" for a in post.category.ancestors}
    )
    pages = sorted({r.path for r in rows})
    transaction.on_commit(lambda: announce.delay(tags, pages), robust=True)
    # Search reads the publications as they are after commit, so it is told the post, not the rows (ADR-0049).
    post_id = str(post.pk)
    transaction.on_commit(lambda: index_post.delay(post_id), robust=True)
