"""Editing endpoints. Permissions are decided by the services, post by post."""

import re
from datetime import datetime, timedelta
from typing import Any, ClassVar
from uuid import UUID

from django.db.models import Case, OuterRef, Q, QuerySet, Subquery, When
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.accounts.models import User
from newsplatform.approvals.models import ApprovalRequest
from newsplatform.common.api import PersonSerializer, StaffView, schema
from newsplatform.common.errors import DomainError, NotFound
from newsplatform.common.locales import Locale
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.common.ratelimit import Limit
from newsplatform.content import authors, diffing, publishing, selectors, services
from newsplatform.content.models import AuthorProfile, Post, PostText, PostType, Revision, Status
from newsplatform.content.workflow import TRANSITIONS
from newsplatform.engagement.policy import CommentMode
from newsplatform.engagement.services import resolved
from newsplatform.media.api import AssetSerializer, asset_body
from newsplatform.media.models import Asset
from newsplatform.rbac import selectors as rbac
from newsplatform.staff_security.authentication import session_of
from newsplatform.taxonomy.models import Category
from newsplatform.taxonomy.selectors import policy_chain

_ANY = "content.create"  # everyone who writes or edits holds it; the services decide the rest


def _any(*methods: str) -> dict[str, str | None]:
    return dict.fromkeys(methods, _ANY)


# ---- shapes ------------------------------------------------------------
class TextSerializer(serializers.Serializer[Any]):
    headline = serializers.CharField(max_length=200, allow_blank=True, required=False)
    standfirst = serializers.CharField(max_length=400, allow_blank=True, required=False)
    slug = serializers.CharField(max_length=100, allow_blank=True, required=False)
    body = serializers.DictField(required=False)
    seo_title = serializers.CharField(max_length=120, allow_blank=True, required=False)
    seo_description = serializers.CharField(max_length=320, allow_blank=True, required=False)
    focus_keyword = serializers.CharField(max_length=80, allow_blank=True, required=False)
    update_note = serializers.CharField(max_length=400, allow_blank=True, required=False)
    correction_note = serializers.CharField(max_length=600, allow_blank=True, required=False)


class TextsSerializer(serializers.Serializer[Any]):
    sw = TextSerializer(required=False)
    en = TextSerializer(required=False)


class OverrideSerializer(serializers.Serializer[Any]):
    """Absent or null inherits."""

    likes = serializers.BooleanField(allow_null=True, required=False)
    comments = serializers.ChoiceField(
        choices=[c.value for c in CommentMode], allow_null=True, required=False
    )
    bookmarks = serializers.BooleanField(allow_null=True, required=False)
    shares = serializers.BooleanField(allow_null=True, required=False)
    reposts = serializers.BooleanField(allow_null=True, required=False)
    live_chat = serializers.BooleanField(allow_null=True, required=False)


class PolicySerializer(serializers.Serializer[Any]):
    likes = serializers.BooleanField()
    comments = serializers.ChoiceField(choices=[c.value for c in CommentMode])
    bookmarks = serializers.BooleanField()
    shares = serializers.BooleanField()
    reposts = serializers.BooleanField()
    live_chat = serializers.BooleanField()


def _ids(limit: int) -> Any:
    return serializers.ListField(child=serializers.UUIDField(), max_length=limit, required=False)


class PostDataSerializer(serializers.Serializer[Any]):
    type = serializers.ChoiceField(choices=PostType.choices, required=False)
    category = serializers.UUIDField(required=False)
    secondary_categories = _ids(6)
    tags = _ids(20)
    regions = _ids(10)
    authors = _ids(10)
    story = serializers.UUIDField(allow_null=True, required=False)
    hero = serializers.UUIDField(allow_null=True, required=False)
    video = serializers.UUIDField(allow_null=True, required=False)
    youtube_id = serializers.RegexField(r"^([A-Za-z0-9_-]{11})?\Z", allow_blank=True, required=False)
    youtube_seconds = serializers.IntegerField(min_value=0, max_value=86_400, required=False)
    source_url = serializers.URLField(max_length=500, allow_blank=True, required=False)
    is_evergreen = serializers.BooleanField(required=False)
    is_sensitive = serializers.BooleanField(required=False)
    content_warning = serializers.CharField(max_length=200, allow_blank=True, required=False)
    breaking_until = serializers.DateTimeField(allow_null=True, required=False)
    embargo_until = serializers.DateTimeField(allow_null=True, required=False)
    live_ended_at = serializers.DateTimeField(allow_null=True, required=False)
    engagement = OverrideSerializer(required=False)
    texts = TextsSerializer(required=False)

    def validate_source_url(self, value: str) -> str:
        if value and not value.startswith(("https://", "http://")):
            raise serializers.ValidationError("Use a web address")
        return value


class NamedSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    name = serializers.CharField()


class PostRowSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    type = serializers.ChoiceField(choices=PostType.choices)
    status = serializers.ChoiceField(choices=Status.choices)
    headline = serializers.CharField()
    locales = serializers.ListField(child=serializers.CharField())
    category = NamedSerializer()
    authors = PersonSerializer(many=True)
    updated_at = serializers.DateTimeField()
    scheduled_at = serializers.DateTimeField(allow_null=True)
    published_at = serializers.DateTimeField(allow_null=True)
    editing = serializers.CharField(allow_blank=True)
    version = serializers.IntegerField()


class NoteSerializer(serializers.ModelSerializer[Any]):
    author = PersonSerializer()

    class Meta:
        from newsplatform.content.models import EditorialNote

        model = EditorialNote
        fields = ["id", "author", "text", "transition", "created_at"]


class PostSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    version = serializers.IntegerField()
    status = serializers.ChoiceField(choices=Status.choices)
    data = PostDataSerializer()  # type: ignore[assignment]
    assets = AssetSerializer(many=True)
    tags = NamedSerializer(many=True)
    people = PersonSerializer(many=True)
    can_edit = serializers.BooleanField()
    can_change_authors = serializers.BooleanField()
    transitions = serializers.ListField(
        child=schema(
            "PostTransition",
            key=serializers.ChoiceField(choices=sorted(TRANSITIONS)),
            note_required=serializers.BooleanField(),
        )
    )
    problems = serializers.ListField(child=serializers.CharField())
    policy = PolicySerializer()
    inherited_policy = PolicySerializer()
    editing = PersonSerializer(allow_null=True)
    unpublished_changes = serializers.BooleanField()
    scheduled_at = serializers.DateTimeField(allow_null=True)
    published_at = serializers.DateTimeField(allow_null=True)
    updated_at = serializers.DateTimeField()
    paths = serializers.DictField(child=serializers.CharField())


def detail(user: User, post: Post) -> dict[str, Any]:
    data = services.snapshot(post)
    used = {UUID(i) for i in (data["hero"], data["video"]) if i}
    for text in data["texts"].values():
        from newsplatform.content import blocks

        used |= blocks.asset_ids(text["body"])
    chain = policy_chain(post.category)
    grants = rbac.grants_for(user)
    holder = services.lock_holder(post)
    published = post.revisions.filter(kind="publish").first()
    return {
        "id": post.pk,
        "version": post.version,
        "status": post.status,
        "data": data,
        "assets": [asset_body(a) for a in Asset.objects.select_related("uploaded_by").filter(pk__in=used)],
        "tags": [{"id": t.pk, "name": t.name_sw} for t in post.tags.order_by("slug")],
        "people": [b.user for b in post.bylines.select_related("user")],
        "can_edit": services.can_edit(user, post, grants),
        "can_change_authors": grants.allows("content.edit_others", post),
        "transitions": [
            {"key": k, "note_required": TRANSITIONS[k].note_required} for k in services.available(user, post)
        ],
        "problems": publishing.problems(post),
        "policy": resolved([*chain, post.engagement]).model_dump(mode="json"),
        "inherited_policy": resolved(chain).model_dump(mode="json"),
        "editing": holder if holder and holder.pk != user.pk else None,
        "unpublished_changes": post.status == Status.PUBLISHED
        and published is not None
        and published.snapshot != data,
        "scheduled_at": post.scheduled_at,
        "published_at": post.published_at,
        "updated_at": post.updated_at,
        "paths": dict(post.publications.values_list("locale", "path")),
    }


def respond(request: Request, post: Post, status: int = 200) -> Response:
    post.refresh_from_db()
    return Response(PostSerializer(detail(session_of(request).user, post)).data, status=status)


# ---- posts ------------------------------------------------------------
class _ByUpdate(TimeCursorPagination):
    ordering = "-updated_at"
    page_size = 30


_FILTERS = [
    OpenApiParameter(n, str, many=n == "status")
    for n in ("status", "type", "category", "author", "q", "from", "to", "cursor")
] + [OpenApiParameter("mine", bool)]


def _when(raw: str) -> datetime:
    value = serializers.DateTimeField().to_internal_value(raw)
    assert isinstance(value, datetime)  # noqa: S101 (type narrowing)
    return value


def _uuid(raw: str) -> UUID:
    value = serializers.UUIDField().to_internal_value(raw)
    assert isinstance(value, UUID)  # noqa: S101 (type narrowing)
    return value


def filtered(request: Request, rows: QuerySet[Post]) -> QuerySet[Post]:
    q = request.query_params
    if wanted := [s for s in q.getlist("status") if s in Status.values]:
        rows = rows.filter(status__in=wanted)
    if q.get("type") in PostType.values:
        rows = rows.filter(type=q["type"])
    if v := q.get("category"):
        ident = _uuid(v)
        rows = rows.filter(Q(category_id=ident) | Q(category__ancestors__contains=[ident]))
    if v := q.get("author"):
        rows = rows.filter(pk__in=Post.objects.filter(bylines__user_id=_uuid(v)).values("pk"))
    if q.get("mine") == "true":
        rows = rows.filter(pk__in=Post.objects.filter(bylines__user=session_of(request).user).values("pk"))
    if v := q.get("q", "").strip()[:100]:
        rows = rows.filter(
            pk__in=PostText.objects.filter(Q(headline__icontains=v) | Q(slug__icontains=v)).values("post_id")
        )
    if v := q.get("from"):
        at = _when(v)
        rows = rows.filter(Q(scheduled_at__gte=at) | Q(scheduled_at=None, published_at__gte=at))
    if v := q.get("to"):
        at = _when(v)
        rows = rows.filter(Q(scheduled_at__lt=at) | Q(scheduled_at=None, published_at__lt=at))
    return rows


def _texts(post: Post) -> list[PostText]:
    """Swahili first: the newsroom's own language names a post in lists."""
    return sorted(post.texts.all(), key=lambda t: t.locale, reverse=True)


def rows_body(posts: list[Post]) -> list[dict[str, Any]]:
    return [
        {
            "id": p.pk,
            "type": p.type,
            "status": p.status,
            "headline": next((t.headline for t in _texts(p) if t.headline), ""),
            "locales": [t.locale for t in _texts(p) if t.headline],
            "category": {"id": p.category_id, "name": p.category_name},  # type: ignore[attr-defined]
            "authors": [b.user for b in p.bylines.all()],
            "updated_at": p.updated_at,
            "scheduled_at": p.scheduled_at,
            "published_at": p.published_at,
            "editing": holder.display_name if (holder := services.lock_holder(p)) else "",
            "version": p.version,
        }
        for p in posts
    ]


def for_rows(rows: QuerySet[Post]) -> QuerySet[Post]:
    from newsplatform.taxonomy.models import CategoryText

    name = CategoryText.objects.filter(category=OuterRef("category")).order_by("-locale").values("name")[:1]
    return (
        rows.annotate(category_name=Subquery(name))
        .select_related("locked_by")
        .prefetch_related("texts", "bylines__user")
        .defer("engagement")
    )


_CALENDAR_DAYS, _CALENDAR_MAX = 45, 2000


class CalendarView(StaffView):
    """Everything published or scheduled in a span, in one answer: a week with a gap in it would mislead."""

    perms: ClassVar[dict[str, str | None]] = {"GET": _ANY}

    @extend_schema(
        operation_id="posts_calendar",
        parameters=[OpenApiParameter(n, OpenApiTypes.DATETIME, required=True) for n in ("from", "to")],
        responses=schema(
            "Calendar",
            truncated=serializers.BooleanField(),
            results=serializers.ListField(
                child=schema(
                    "CalendarEntry",
                    id=serializers.UUIDField(),
                    status=serializers.ChoiceField(choices=Status.choices),
                    headline=serializers.CharField(),
                    at=serializers.DateTimeField(),
                )
            ),
        ),
    )
    def get(self, request: Request) -> Response:
        start, end = (_when(request.query_params.get(n, "")) for n in ("from", "to"))
        if not timedelta(0) < end - start <= timedelta(days=_CALENDAR_DAYS):
            raise DomainError("Choose a shorter span.", code="validation_error")
        rows = list(
            selectors.visible_posts(session_of(request).user)
            .filter(
                Q(status=Status.SCHEDULED, scheduled_at__gte=start, scheduled_at__lt=end)
                | Q(status=Status.PUBLISHED, published_at__gte=start, published_at__lt=end)
            )
            .annotate(
                at=Case(When(status=Status.SCHEDULED, then="scheduled_at"), default="published_at"),
                headline=Subquery(
                    PostText.objects.filter(post=OuterRef("pk"))
                    .exclude(headline="")
                    .order_by("-locale")
                    .values("headline")[:1]
                ),
            )
            .order_by("at", "pk")
            .values("id", "status", "headline", "at")[: _CALENDAR_MAX + 1]
        )
        results = [{**r, "headline": r["headline"] or ""} for r in rows[:_CALENDAR_MAX]]
        return Response({"truncated": len(rows) > _CALENDAR_MAX, "results": results})


class PostListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _ANY, "POST": _ANY}

    @extend_schema(operation_id="posts_list", parameters=_FILTERS, responses=page_of(PostRowSerializer))
    def get(self, request: Request) -> Response:
        rows = filtered(request, selectors.visible_posts(session_of(request).user))
        pages = _ByUpdate()
        page = pages.paginate_queryset(for_rows(rows), request, view=self) or []
        return pages.get_paginated_response(PostRowSerializer(rows_body(page), many=True).data)

    class PostCreate(serializers.Serializer[Any]):
        type = serializers.ChoiceField(choices=PostType.choices)
        category = serializers.UUIDField()
        locale = serializers.ChoiceField(choices=Locale.choices)
        headline = serializers.CharField(max_length=200, allow_blank=True, default="")

    @extend_schema(operation_id="posts_create", request=PostCreate, responses={201: PostSerializer})
    def post(self, request: Request) -> Response:
        data = self.PostCreate(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        category = Category.objects.filter(pk=d["category"]).exclude(visibility="archived").first()
        if category is None:
            raise NotFound("Not found")
        post = services.create(
            actor=session_of(request).user,
            type=d["type"],
            category=category,
            locale=d["locale"],
            headline=d["headline"],
        )
        return respond(request, post, 201)


class PostView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("GET", "PUT")
    limit = Limit(400, 60)  # autosave

    @extend_schema(operation_id="posts_get", responses=PostSerializer)
    def get(self, request: Request, post_id: UUID) -> Response:
        return respond(request, services.get_for(session_of(request).user, post_id))

    class PostSave(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=1)
        autosave = serializers.BooleanField(default=False)
        note = serializers.CharField(max_length=300, allow_blank=True, default="")
        data = PostDataSerializer()  # type: ignore[assignment]

    @extend_schema(operation_id="posts_save", request=PostSave, responses=PostSerializer)
    def put(self, request: Request, post_id: UUID) -> Response:
        data = self.PostSave(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        post = services.save(
            actor=session_of(request).user,
            post_id=post_id,
            version=d["version"],
            data=d["data"],
            autosave=d["autosave"],
            note=d["note"],
        )
        return respond(request, post)


class PostLockView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("POST", "DELETE")
    limit = Limit(120, 60)

    class PostLock(serializers.Serializer[Any]):
        force = serializers.BooleanField(default=False)

    @extend_schema(
        operation_id="posts_lock",
        request=PostLock,
        responses=schema("Lock", version=serializers.IntegerField()),
    )
    def post(self, request: Request, post_id: UUID) -> Response:
        data = self.PostLock(data=request.data)
        data.is_valid(raise_exception=True)
        post = services.take_lock(
            actor=session_of(request).user, post_id=post_id, force=data.validated_data["force"]
        )
        return Response({"version": post.version})

    @extend_schema(operation_id="posts_unlock", responses={204: None})
    def delete(self, request: Request, post_id: UUID) -> Response:
        services.release_lock(actor=session_of(request).user, post_id=post_id)
        return Response(status=204)


class PostTransitionView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("POST")

    class PostTransitionRequest(serializers.Serializer[Any]):
        key = serializers.ChoiceField(choices=sorted(TRANSITIONS))
        version = serializers.IntegerField(min_value=1)
        note = serializers.CharField(max_length=2000, allow_blank=True, default="")
        scheduled_at = serializers.DateTimeField(allow_null=True, default=None)

    @extend_schema(operation_id="posts_transition", request=PostTransitionRequest, responses=PostSerializer)
    def post(self, request: Request, post_id: UUID) -> Response:
        data = self.PostTransitionRequest(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        post = services.transition(
            actor=session_of(request).user,
            post_id=post_id,
            key=d["key"],
            version=d["version"],
            note=d["note"],
            scheduled_at=d["scheduled_at"],
        )
        return respond(request, post)


class PostLiveUpdateView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("POST")

    class LiveUpdateRequest(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=1)
        locale = serializers.ChoiceField(choices=Locale.choices)
        block = serializers.DictField()
        publish = serializers.BooleanField(default=True)

    @extend_schema(operation_id="posts_live_update", request=LiveUpdateRequest, responses=PostSerializer)
    def post(self, request: Request, post_id: UUID) -> Response:
        data = self.LiveUpdateRequest(data=request.data)
        data.is_valid(raise_exception=True)
        post = services.add_live_update(
            actor=session_of(request).user,
            post_id=post_id,
            version=data.validated_data["version"],
            locale=data.validated_data["locale"],
            update=data.validated_data["block"],
            publish=data.validated_data["publish"],
        )
        return respond(request, post)


class PostPreviewView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("GET")

    @extend_schema(
        operation_id="posts_preview",
        parameters=[OpenApiParameter("locale", str, required=True)],
        responses=schema(
            "PostPreview", article=serializers.JSONField(), media_base_url=serializers.CharField()
        ),
    )
    def get(self, request: Request, post_id: UUID) -> Response:
        from newsplatform.media.storage import base_url

        post = services.get_for(session_of(request).user, post_id)
        locale = request.query_params.get("locale", "sw")
        return Response({"article": publishing.preview(post, locale), "media_base_url": base_url()})


# ---- revisions, notes ------------------------------------------------------------
class RevisionSerializer(serializers.ModelSerializer[Revision]):
    author = PersonSerializer()

    class Meta:
        model = Revision
        fields = ["number", "kind", "author", "note", "created_at", "updated_at"]


class _ByNumber(TimeCursorPagination):
    ordering = "-number"


class RevisionListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("GET")

    @extend_schema(operation_id="revisions_list", responses=page_of(RevisionSerializer))
    def get(self, request: Request, post_id: UUID) -> Response:
        post = services.get_for(session_of(request).user, post_id)
        pages = _ByNumber()
        rows = post.revisions.select_related("author").defer("snapshot")
        page = pages.paginate_queryset(rows, request, view=self)
        return pages.get_paginated_response(RevisionSerializer(page, many=True).data)


_Words = serializers.ListField(
    child=schema(
        "DiffRun",
        op=serializers.ChoiceField(choices=["same", "add", "del"]),
        text=serializers.CharField(),
    )
)
DiffSerializer = schema(
    "RevisionDiff",
    fields=serializers.ListField(child=serializers.CharField()),
    texts=serializers.ListField(
        child=schema(
            "TextDiff",
            locale=serializers.CharField(),
            fields=serializers.ListField(
                child=schema("FieldDiff", field=serializers.CharField(), words=_Words)
            ),
            blocks=serializers.ListField(
                child=schema(
                    "BlockDiff",
                    op=serializers.ChoiceField(choices=["same", "added", "removed", "changed", "moved"]),
                    id=serializers.CharField(),
                    type=serializers.CharField(),
                    words=_Words,
                )
            ),
        )
    ),
)


class RevisionDiffView(StaffView):
    """`to` against `from`; without `from`, against the revision before it."""

    perms: ClassVar[dict[str, str | None]] = _any("GET")

    @extend_schema(
        operation_id="revisions_diff",
        parameters=[OpenApiParameter("from", int)],
        responses=DiffSerializer,
    )
    def get(self, request: Request, post_id: UUID, number: int) -> Response:
        post = services.get_for(session_of(request).user, post_id)
        new = post.revisions.filter(number=number).first()
        raw = request.query_params.get("from", "")
        if re.fullmatch(r"\d{1,9}", raw):
            old = post.revisions.filter(number=int(raw)).first()
        else:
            old = post.revisions.filter(number__lt=number).first()
        if new is None or (raw and old is None):
            raise NotFound("Not found")
        return Response(diffing.revisions(old.snapshot if old else {"texts": {}}, new.snapshot))


class RevisionRestoreView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("POST")

    class RestoreRequest(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=1)

    @extend_schema(operation_id="revisions_restore", request=RestoreRequest, responses=PostSerializer)
    def post(self, request: Request, post_id: UUID, number: int) -> Response:
        data = self.RestoreRequest(data=request.data)
        data.is_valid(raise_exception=True)
        post = services.restore_revision(
            actor=session_of(request).user,
            post_id=post_id,
            number=number,
            version=data.validated_data["version"],
        )
        return respond(request, post)


class NoteListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _any("GET", "POST")

    @extend_schema(operation_id="notes_list", responses=page_of(NoteSerializer))
    def get(self, request: Request, post_id: UUID) -> Response:
        post = services.get_for(session_of(request).user, post_id)
        pages = TimeCursorPagination()
        page = pages.paginate_queryset(post.notes.select_related("author"), request, view=self)
        return pages.get_paginated_response(NoteSerializer(page, many=True).data)

    class NoteCreate(serializers.Serializer[Any]):
        text = serializers.CharField(max_length=2000)

    @extend_schema(operation_id="notes_create", request=NoteCreate, responses={201: NoteSerializer})
    def post(self, request: Request, post_id: UUID) -> Response:
        data = self.NoteCreate(data=request.data)
        data.is_valid(raise_exception=True)
        note = services.add_note(
            actor=session_of(request).user, post_id=post_id, text=data.validated_data["text"]
        )
        return Response(NoteSerializer(note).data, status=201)


class BulkView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _ANY}
    limit = Limit(20, 60)

    class BulkRequest(serializers.Serializer[Any]):
        key = serializers.ChoiceField(choices=services.BULK_ACTIONS)
        ids = serializers.ListField(
            child=serializers.UUIDField(), min_length=1, max_length=services.BULK_LIMIT
        )
        note = serializers.CharField(max_length=2000, allow_blank=True, default="")

    @extend_schema(
        operation_id="posts_bulk",
        request=BulkRequest,
        responses=schema(
            "BulkResult",
            approval_required=serializers.BooleanField(),
            results=serializers.ListField(
                child=schema("BulkItem", id=serializers.UUIDField(), result=serializers.CharField())
            ),
        ),
    )
    def post(self, request: Request) -> Response:
        data = self.BulkRequest(data=request.data)
        data.is_valid(raise_exception=True)
        out = services.bulk(actor=session_of(request).user, **data.validated_data)
        pending = isinstance(out, ApprovalRequest)
        return Response({"approval_required": pending, "results": [] if pending else out})


# ---- authors ------------------------------------------------------------
class AuthorSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    display_name = serializers.CharField()
    slug = serializers.CharField()
    title_sw = serializers.CharField()
    title_en = serializers.CharField()
    bio_sw = serializers.CharField()
    bio_en = serializers.CharField()
    expertise = serializers.ListField(child=serializers.CharField())
    links = serializers.ListField(child=serializers.CharField())
    avatar = AssetSerializer(allow_null=True)


def author_body(profile: AuthorProfile) -> dict[str, Any]:
    return {
        "id": profile.user_id,
        "display_name": profile.user.display_name,
        **{k: getattr(profile, k) for k in ("slug", "title_sw", "title_en", "bio_sw", "bio_en")},
        "expertise": profile.expertise,
        "links": profile.links,
        "avatar": asset_body(profile.avatar) if profile.avatar else None,
    }


class AuthorListView(StaffView):
    """Who can be named on a post."""

    perms: ClassVar[dict[str, str | None]] = {"GET": _ANY}

    @extend_schema(
        operation_id="authors_list",
        parameters=[OpenApiParameter("q", str)],
        responses=PersonSerializer(many=True),
    )
    def get(self, request: Request) -> Response:
        rows = User.objects.filter(is_staff_member=True, status="active").order_by("display_name")
        if q := request.query_params.get("q", "").strip()[:80]:
            rows = rows.filter(display_name__icontains=q)
        return Response(PersonSerializer(rows[:50], many=True).data)


class AuthorView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _ANY, "PUT": _ANY}

    class AuthorSave(serializers.Serializer[Any]):
        title_sw = serializers.CharField(max_length=120, allow_blank=True, required=False)
        title_en = serializers.CharField(max_length=120, allow_blank=True, required=False)
        bio_sw = serializers.CharField(max_length=2000, allow_blank=True, required=False)
        bio_en = serializers.CharField(max_length=2000, allow_blank=True, required=False)
        expertise = serializers.ListField(
            child=serializers.CharField(max_length=60), max_length=authors.MAX_EXPERTISE, required=False
        )
        links = serializers.ListField(
            child=serializers.CharField(max_length=300), max_length=authors.MAX_LINKS, required=False
        )
        avatar = serializers.UUIDField(allow_null=True, required=False)

    @extend_schema(operation_id="authors_get", responses=AuthorSerializer)
    def get(self, request: Request, user_id: UUID) -> Response:
        user = User.objects.filter(pk=user_id, is_staff_member=True).first()
        if user is None:
            raise NotFound("Not found")
        return Response(AuthorSerializer(author_body(authors.ensure(user, save=False))).data)

    @extend_schema(operation_id="authors_save", request=AuthorSave, responses=AuthorSerializer)
    def put(self, request: Request, user_id: UUID) -> Response:
        data = self.AuthorSave(data=request.data)
        data.is_valid(raise_exception=True)
        profile = authors.update(actor=session_of(request).user, user_id=user_id, data=data.validated_data)
        return Response(AuthorSerializer(author_body(profile)).data)
