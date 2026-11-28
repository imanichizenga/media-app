"""What readers get. Identical for everyone, so every response can live in the CDN (ADR-0026)."""

from collections.abc import Iterable
from datetime import timedelta
from typing import Any, ClassVar

from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from newsplatform.common.errors import DomainError, NotFound
from newsplatform.common.locales import DEFAULT, Locale
from newsplatform.content import authors, selectors
from newsplatform.content import public_shapes as shapes
from newsplatform.content.models import AuthorProfile, Feed, PostType
from newsplatform.rbac.permissions import PublicEndpoint
from newsplatform.search import engine
from newsplatform.seo import paths
from newsplatform.seo.services import resolve
from newsplatform.taxonomy.models import Story, Tag
from newsplatform.taxonomy.selectors import Node, tree

MAX_LIMIT = 50
_LOCALE = OpenApiParameter("locale", str, enum=Locale.values, default=DEFAULT)
_PAGE = [OpenApiParameter("cursor", str), OpenApiParameter("limit", int, default=selectors.PAGE)]


class PublicView(APIView):
    """GET only, no cookies, no user. Anything about a person is a separate endpoint (M4)."""

    authentication_classes = []
    permission_classes = [PublicEndpoint]
    http_method_names = ["get", "head", "options"]
    # Browsers revalidate quickly; the CDN keeps it until a purge, and serves it while refreshing.
    browser_seconds: ClassVar[int] = 30
    edge_seconds: ClassVar[int] = 300

    def cached(self, data: Any, tags: Iterable[str]) -> Response:
        cache = (
            f"public, max-age={self.browser_seconds}, s-maxage={self.edge_seconds}, "
            f"stale-while-revalidate=600, stale-if-error=86400"
        )
        keys = " ".join(sorted(set(tags)))
        return Response(data, headers={"Cache-Control": cache, "Surrogate-Key": keys})

    def handle_exception(self, exc: Exception) -> Response:
        response: Response = super().handle_exception(exc)
        # A missing page is asked for again and again by crawlers, but must appear soon after publishing.
        missing = response.status_code == 404
        response["Cache-Control"] = "public, max-age=0, s-maxage=30" if missing else "no-store"
        return response


def locale_of(request: Request) -> str:
    value: str = request.query_params.get("locale", DEFAULT)
    if value not in Locale.values:
        raise DomainError("Unknown language", code="validation_error")
    return value


def page_args(request: Request) -> dict[str, Any]:
    raw = request.query_params.get("limit", str(selectors.PAGE))
    if not raw.isdigit() or not 1 <= int(raw) <= MAX_LIMIT:
        raise DomainError("Invalid limit", code="validation_error")
    return {"cursor": request.query_params.get("cursor", "")[:200], "limit": int(raw)}


def _brief(node: Node, locale: str) -> dict[str, Any]:
    slug = node.slug(locale)
    return {
        "id": str(node.category.pk),
        "name": node.name(locale),
        "short_name": node.short_name(locale),
        "slug": slug,
        "path": paths.category_path(locale, slug),
        "color": node.category.color,
    }


def _card_tags(cards: list[dict[str, Any]]) -> set[str]:
    return {f"post-{c['id']}" for c in cards}


class HomeView(PublicView):
    edge_seconds = 120

    @extend_schema(operation_id="home", auth=[], parameters=[_LOCALE], responses=shapes.HomeSerializer)
    def get(self, request: Request) -> Response:
        locale = locale_of(request)
        nodes = tree(public_only=True)
        roots = [n for n in nodes.values() if n.category.parent_id is None and locale in n.texts][:12]
        wanted = [
            (str(Feed.ALL), "", 40),
            (str(Feed.TYPE), str(PostType.VIDEO), 8),
            (str(Feed.TYPE), str(PostType.YOUTUBE), 8),
            (str(Feed.TYPE), str(PostType.SHORT), 12),
            # Enough for a row one slides through (web: components/parts.tsx Rail).
            *((str(Feed.CATEGORY), str(n.category.pk), 12) for n in roots),
        ]
        everything, videos, youtube, shorts, *sections = selectors.several(locale, wanted)
        # Shorts have their own strip and their own screen.
        river = [c for c in everything if c["type"] != PostType.SHORT]
        lead = [c for c in river if c["image"] and not c["is_sensitive"]][:5]
        leading = {c["id"] for c in lead}
        clips = sorted([*videos, *youtube], key=lambda c: c["published_at"], reverse=True)[:8]
        return self.cached(
            {
                "breaking": selectors.breaking(locale),
                "live": selectors.live(locale),
                "lead": lead,
                "latest": [c for c in river if c["id"] not in leading][:20],
                "videos": clips,
                "shorts": shorts,
                "sections": [
                    {"category": _brief(n, locale), "results": found}
                    for n, found in zip(roots, sections, strict=True)
                    if found
                ],
            },
            ["latest", "navigation"],
        )


class _FeedView(PublicView):
    def feed(self, request: Request, kind: str, key: str, tags: list[str], **extra: Any) -> Response:
        found, after = selectors.feed(locale_of(request), kind, key, **page_args(request))
        return self.cached({**extra, "results": found, "next_cursor": after}, [*tags, *_card_tags(found)])


class LatestView(_FeedView):
    edge_seconds = 60

    @extend_schema(
        operation_id="latest", auth=[], parameters=[_LOCALE, *_PAGE], responses=shapes.FeedPageSerializer
    )
    def get(self, request: Request) -> Response:
        return self.feed(request, Feed.ALL, "", ["latest"])


class TypeView(_FeedView):
    """Video list, shorts, galleries, opinion…"""

    kinds: ClassVar[tuple[str, ...]] = (
        PostType.VIDEO,
        PostType.SHORT,
        PostType.YOUTUBE,
        PostType.GALLERY,
        PostType.OPINION,
        PostType.LIVE_BLOG,
    )

    @extend_schema(
        operation_id="by_type",
        auth=[],
        parameters=[_LOCALE, *_PAGE, OpenApiParameter("kind", str, "path", enum=[str(k) for k in kinds])],
        responses=shapes.FeedPageSerializer,
    )
    def get(self, request: Request, kind: str) -> Response:
        if kind not in self.kinds:
            raise NotFound("Not found")
        return self.feed(request, Feed.TYPE, kind, ["latest"])


class CategoryFeedView(_FeedView):
    @extend_schema(
        operation_id="category",
        auth=[],
        parameters=[_LOCALE, *_PAGE],
        responses=shapes.CategoryPageSerializer,
    )
    def get(self, request: Request, slug: str) -> Response:
        locale = locale_of(request)
        nodes = tree(public_only=True)
        node = next((n for n in nodes.values() if locale in n.texts and n.slug(locale) == slug), None)
        if node is None:
            raise NotFound("Not found")
        c, text = node.category, node.texts[locale]
        children = [n for n in nodes.values() if n.category.parent_id == c.pk and locale in n.texts]
        return self.feed(
            request,
            Feed.CATEGORY,
            str(c.pk),
            [f"category-{c.pk}", "navigation"],
            category={
                **_brief(node, locale),
                "icon": c.icon,
                "description": text.description,
                "seo_title": text.seo_title or text.name,
                "seo_description": text.seo_description or text.description,
                "parents": [_brief(nodes[a], locale) for a in c.ancestors],
                "children": [_brief(n, locale) for n in children],
                "translations": [
                    {"locale": loc, "path": paths.category_path(loc, t.slug)}
                    for loc, t in sorted(node.texts.items())
                    if loc != locale
                ],
            },
        )


class TagFeedView(_FeedView):
    @extend_schema(
        operation_id="tag", auth=[], parameters=[_LOCALE, *_PAGE], responses=shapes.TagPageSerializer
    )
    def get(self, request: Request, slug: str) -> Response:
        locale = locale_of(request)
        row = Tag.objects.filter(slug=slug, merged_into=None).first()
        if row is None:
            raise NotFound("Not found")
        return self.feed(
            request,
            Feed.TAG,
            str(row.pk),
            [f"tag-{slug}"],
            tag={
                "slug": slug,
                "name": row.name_en if locale == "en" else row.name_sw,
                "path": paths.tag_path(locale, slug),
            },
        )


class StoryFeedView(_FeedView):
    @extend_schema(
        operation_id="story", auth=[], parameters=[_LOCALE, *_PAGE], responses=shapes.StoryPageSerializer
    )
    def get(self, request: Request, slug: str) -> Response:
        locale = locale_of(request)
        row = Story.objects.filter(slug=slug).first()
        if row is None:
            raise NotFound("Not found")
        en = locale == "en"
        return self.feed(
            request,
            Feed.STORY,
            str(row.pk),
            [f"story-{slug}"],
            story={
                "slug": slug,
                "title": row.title_en if en else row.title_sw,
                "path": paths.story_path(locale, slug),
                "summary": row.summary_en if en else row.summary_sw,
                "is_active": row.is_active,
            },
        )


class AuthorFeedView(_FeedView):
    @extend_schema(
        operation_id="author", auth=[], parameters=[_LOCALE, *_PAGE], responses=shapes.AuthorPageSerializer
    )
    def get(self, request: Request, slug: str) -> Response:
        row = AuthorProfile.objects.select_related("user", "avatar").filter(slug=slug).first()
        if row is None:
            raise NotFound("Not found")
        return self.feed(
            request,
            Feed.AUTHOR,
            str(row.user_id),
            [f"author-{row.user_id}"],
            author=authors.public(row, locale_of(request)),
        )


class ArticleView(PublicView):
    @extend_schema(operation_id="article", auth=[], parameters=[_LOCALE], responses=shapes.ArticleSerializer)
    def get(self, request: Request, slug: str) -> Response:
        from newsplatform.subscriptions.services import locked

        row = selectors.article(locale_of(request), slug)
        tags = [f"post-{row.post_id}", f"category-{row.category_id}"]
        tags += [f"author-{a['id']}" for a in row.article["authors"]]
        article = selectors.current(row.article)
        if article["premium"]:
            tags.append("premium")
        # Shared by everyone, so a story for subscribers is its opening here (subscriptions/posts/{id}).
        return self.cached({**locked(article), "modified_at": row.modified_at.isoformat()}, tags)


class RelatedView(PublicView):
    edge_seconds = 600

    @extend_schema(operation_id="related", auth=[], parameters=[_LOCALE], responses=shapes.RelatedSerializer)
    def get(self, request: Request, slug: str) -> Response:
        row = selectors.article(locale_of(request), slug)
        found = selectors.related(row)
        return self.cached(
            {"results": found},
            [f"post-{row.post_id}", f"category-{row.category_id}", *_card_tags(found)],
        )


class NavigationView(PublicView):
    edge_seconds = 3600

    @extend_schema(
        operation_id="navigation",
        auth=[],
        parameters=[_LOCALE],
        responses=shapes.NavigationItemSerializer(many=True),
    )
    def get(self, request: Request) -> Response:
        locale = locale_of(request)
        nodes = [n for n in tree(public_only=True).values() if locale in n.texts]
        return self.cached(
            [
                {
                    **_brief(n, locale),
                    "icon": n.category.icon,
                    "children": [_brief(k, locale) for k in nodes if k.category.parent_id == n.category.pk],
                }
                for n in nodes
                if n.category.parent_id is None
            ],
            ["navigation"],
        )


_SINCE = {
    "24h": timedelta(hours=24),
    "7d": timedelta(days=7),
    "30d": timedelta(days=30),
    "1y": timedelta(days=365),
}


def _search_params(request: Request, locale: str) -> engine.Params:
    q = request.query_params
    types = tuple(t for t in q.get("type", "").split(",") if t)
    if any(t not in PostType.values for t in types):
        raise DomainError("Unknown type", code="validation_error")
    categories: tuple[str, ...] = ()
    if slug := q.get("category", ""):
        node = next((n for n in tree(public_only=True).values() if n.slug(locale) == slug), None)
        if node is None:
            raise DomainError("Unknown category", code="validation_error")
        categories = (str(node.category.pk),)
    since = q.get("since", "")
    if since and since not in _SINCE:
        raise DomainError("Unknown period", code="validation_error")
    sort = q.get("sort", "relevance")
    if sort not in ("relevance", "newest"):
        raise DomainError("Unknown order", code="validation_error")
    return engine.Params(
        q=engine.normalise(q.get("q", "")),
        locale=locale,
        types=types,
        categories=categories,
        since=timezone.now() - _SINCE[since] if since else None,
        sort=sort,  # type: ignore[arg-type]
        cursor=q.get("cursor", "")[:500] or None,
    )


class SearchView(PublicView):
    """ADR-0049: words, typing mistakes and first letters, in Swahili and English; newest first on a tie."""

    browser_seconds = 30
    edge_seconds = 60

    @extend_schema(
        operation_id="search",
        auth=[],
        parameters=[
            _LOCALE,
            OpenApiParameter("q", str, required=True),
            OpenApiParameter("type", str, description="Comma-separated post types"),
            OpenApiParameter("category", str, description="A section's slug; its subsections are included"),
            OpenApiParameter("since", str, enum=list(_SINCE)),
            OpenApiParameter("sort", str, enum=["relevance", "newest"], default="relevance"),
            OpenApiParameter("cursor", str),
        ],
        responses=shapes.SearchSerializer,
    )
    def get(self, request: Request) -> Response:
        params = _search_params(request, locale_of(request))
        if not params.q:
            empty = {
                "available": True,
                "query": "",
                "total": 0,
                "total_is_exact": True,
                "engine": "opensearch",
            }
            return self.cached({**empty, "next_cursor": None, "results": []}, ["search"])
        page = engine.search(params)
        data = {
            "available": True,
            "query": params.q,
            "total": page.total,
            "total_is_exact": page.total_is_exact,
            "engine": page.engine,
            "next_cursor": page.next_cursor,
            "results": [{"card": h.card, "snippet": h.snippet} for h in page.results],
        }
        return self.cached(data, ["search", "latest"])


class SuggestView(PublicView):
    """Headlines as the reader types (ADR-0049)."""

    browser_seconds = 30
    edge_seconds = 60

    @extend_schema(
        operation_id="search_suggest",
        auth=[],
        parameters=[_LOCALE, OpenApiParameter("q", str, required=True)],
        responses=shapes.SuggestSerializer,
    )
    def get(self, request: Request) -> Response:
        locale = locale_of(request)
        q = engine.normalise(request.query_params.get("q", ""))
        results = engine.suggest(q, locale) if len(q) >= 2 else []
        return self.cached({"query": q, "results": results}, ["search", "latest"])


class ResolveView(PublicView):
    """Where an old address lives now. The website asks before it answers 404."""

    @extend_schema(
        operation_id="resolve",
        auth=[],
        parameters=[OpenApiParameter("path", str, required=True)],
        responses=shapes.ResolveSerializer,
    )
    def get(self, request: Request) -> Response:
        found = resolve(request.query_params.get("path", ""))
        if found is None:
            raise NotFound("Not found")
        return self.cached({"path": found}, ["redirects"])
