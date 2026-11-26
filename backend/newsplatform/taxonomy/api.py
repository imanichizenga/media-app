from typing import Any, ClassVar
from uuid import UUID

from django.db.models import Count, Q
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import PersonSerializer, StaffView, schema
from newsplatform.common.errors import NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.rbac import selectors as rbac
from newsplatform.rbac.models import RoleAssignment
from newsplatform.staff_security.authentication import session_of
from newsplatform.taxonomy import selectors, services
from newsplatform.taxonomy.models import Category, Region, Story, Tag, Visibility

_READ = "content.create"
_MANAGE = "taxonomy.manage"


class CategoryTextSerializer(serializers.Serializer[Any]):
    name = serializers.CharField(max_length=80)
    short_name = serializers.CharField(
        max_length=14,
        allow_blank=True,
        default="",
        help_text="On a card when the whole name does not fit. Empty: the name.",
    )
    slug = serializers.SlugField(max_length=80, allow_blank=True, default="")
    description = serializers.CharField(max_length=500, allow_blank=True, default="")
    seo_title = serializers.CharField(max_length=120, allow_blank=True, default="")
    seo_description = serializers.CharField(max_length=320, allow_blank=True, default="")


class CategoryTextsSerializer(serializers.Serializer[Any]):
    sw = CategoryTextSerializer(required=False)
    en = CategoryTextSerializer(required=False)


class CategorySerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    parent = serializers.UUIDField(allow_null=True)  # type: ignore[assignment]
    depth = serializers.IntegerField()
    position = serializers.IntegerField()
    icon = serializers.CharField()
    color = serializers.CharField()
    visibility = serializers.ChoiceField(choices=Visibility.choices)
    engagement = serializers.DictField()
    version = serializers.IntegerField()
    texts = CategoryTextsSerializer()
    posts = serializers.IntegerField()
    editors = PersonSerializer(many=True)
    can_manage = serializers.BooleanField()
    can_create = serializers.BooleanField()


def _categories(request: Request) -> list[dict[str, Any]]:
    grants = rbac.grants_for(session_of(request).user)
    nodes = selectors.tree()
    counts = dict(Category.objects.annotate(n=Count("posts")).values_list("pk", "n"))
    editors: dict[str, list[Any]] = {}
    rows = RoleAssignment.objects.filter(scope_type="category").select_related("user").order_by("created_at")
    for row in rows:
        people = editors.setdefault(row.scope_id, [])
        if row.user not in people:
            people.append(row.user)
    manage, create = "taxonomy.manage" in grants.everywhere, "content.create" in grants.everywhere
    # Branch rights from the tree already in memory, instead of a query per category.
    scoped = {ident: perms for (kind, ident), perms in grants.scoped.items() if kind == "category"}
    out = []
    for node in nodes.values():
        c = node.category
        branch = frozenset[str]().union(*(scoped.get(str(i), frozenset()) for i in [c.pk, *c.ancestors]))
        out.append(
            {
                "id": c.pk,
                "parent": c.parent_id,
                "depth": c.depth,
                "position": c.position,
                "icon": c.icon,
                "color": c.color,
                "visibility": c.visibility,
                "engagement": c.engagement,
                "version": c.version,
                "texts": {loc: services.text_body(t) for loc, t in node.texts.items()},
                "posts": counts.get(c.pk, 0),
                "editors": editors.get(str(c.pk), []),
                "can_manage": manage or "taxonomy.manage" in branch,
                "can_create": create or "content.create" in branch,
            }
        )
    return out


def _category(category_id: Any) -> Category:
    row = Category.objects.filter(pk=category_id).first()
    if row is None:
        raise NotFound("Not found")
    return row


class CategorySave(serializers.Serializer[Any]):
    parent = serializers.UUIDField(allow_null=True, default=None)  # type: ignore[assignment]
    version = serializers.IntegerField(min_value=0, default=0)
    icon = serializers.SlugField(max_length=40, allow_blank=True, default="")
    color = serializers.RegexField(r"^(#[0-9a-fA-F]{6})?\Z", allow_blank=True, default="")
    visibility = serializers.ChoiceField(choices=Visibility.choices, default="public")
    engagement = serializers.DictField(default=dict)
    texts = CategoryTextsSerializer()


class CategoryListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _READ, "POST": _MANAGE}

    @extend_schema(operation_id="categories_list", responses=CategorySerializer(many=True))
    def get(self, request: Request) -> Response:
        return Response(CategorySerializer(_categories(request), many=True).data)

    @extend_schema(
        operation_id="categories_create",
        request=CategorySave,
        responses={201: schema("CategoryRef", id=serializers.UUIDField())},
    )
    def post(self, request: Request) -> Response:
        data = CategorySave(data=request.data)
        data.is_valid(raise_exception=True)
        d = dict(data.validated_data)
        parent = d.pop("parent")
        d.pop("version")
        row = services.save_category(
            actor=session_of(request).user,
            category=None,
            parent=_category(parent) if parent else None,
            **d,
        )
        return Response({"id": row.pk}, status=201)


class CategoryView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"PUT": _MANAGE}

    @extend_schema(
        operation_id="categories_save",
        request=CategorySave,
        responses=schema("CategoryVersion", version=serializers.IntegerField()),
    )
    def put(self, request: Request, category_id: UUID) -> Response:
        data = CategorySave(data=request.data)
        data.is_valid(raise_exception=True)
        d = dict(data.validated_data)
        d.pop("parent")  # moving has its own endpoint, with its own checks
        row = services.save_category(
            actor=session_of(request).user, category=_category(category_id), parent=None, **d
        )
        return Response({"version": row.version})


class CategoryMoveView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _MANAGE}

    class CategoryMove(serializers.Serializer[Any]):
        parent = serializers.UUIDField(allow_null=True)  # type: ignore[assignment]
        position = serializers.IntegerField(min_value=0)

    @extend_schema(operation_id="categories_move", request=CategoryMove, responses={204: None})
    def post(self, request: Request, category_id: UUID) -> Response:
        data = self.CategoryMove(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        services.move_category(
            actor=session_of(request).user,
            category=_category(category_id),
            parent=_category(d["parent"]) if d["parent"] else None,
            position=d["position"],
        )
        return Response(status=204)


class CategoryMergeView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _MANAGE}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    class CategoryMerge(serializers.Serializer[Any]):
        target = serializers.UUIDField()

    @extend_schema(operation_id="categories_merge", request=CategoryMerge, responses={204: None})
    def post(self, request: Request, category_id: UUID) -> Response:
        data = self.CategoryMerge(data=request.data)
        data.is_valid(raise_exception=True)
        services.merge_category(
            actor=session_of(request).user,
            source=_category(category_id),
            target=_category(data.validated_data["target"]),
        )
        return Response(status=204)


# ---- tags ------------------------------------------------------------
class TagSerializer(serializers.ModelSerializer[Tag]):
    posts = serializers.IntegerField(source="post_count", read_only=True, default=0)
    synonyms = serializers.ListField(child=serializers.CharField())

    class Meta:
        model = Tag
        fields = ["id", "slug", "name_sw", "name_en", "synonyms", "posts"]


class TagSave(serializers.Serializer[Any]):
    name_sw = serializers.CharField(max_length=80)
    name_en = serializers.CharField(max_length=80)
    slug = serializers.SlugField(max_length=80, allow_blank=True, default="")
    synonyms = serializers.ListField(child=serializers.CharField(max_length=80), max_length=40, default=list)


def _tag(tag_id: Any) -> Tag:
    row = Tag.objects.filter(pk=tag_id, merged_into=None).first()
    if row is None:
        raise NotFound("Not found")
    return row


class TagListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _READ, "POST": _MANAGE}

    @extend_schema(
        operation_id="tags_list",
        parameters=[OpenApiParameter("q", str), OpenApiParameter("cursor", str)],
        responses=page_of(TagSerializer),
    )
    def get(self, request: Request) -> Response:
        rows = Tag.objects.filter(merged_into=None).annotate(post_count=Count("posts"))
        if v := request.query_params.get("q", "").strip().lower()[:80]:
            rows = rows.filter(
                Q(name_sw__icontains=v) | Q(name_en__icontains=v) | Q(slug__icontains=v)
                | Q(synonyms__contains=[v])
            )  # fmt: skip
        pages = TimeCursorPagination()
        page = pages.paginate_queryset(rows, request, view=self)
        return pages.get_paginated_response(TagSerializer(page, many=True).data)

    @extend_schema(operation_id="tags_create", request=TagSave, responses={201: TagSerializer})
    def post(self, request: Request) -> Response:
        data = TagSave(data=request.data)
        data.is_valid(raise_exception=True)
        row = services.save_tag(actor=session_of(request).user, tag=None, **data.validated_data)
        return Response(TagSerializer(row).data, status=201)


class TagView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"PUT": _MANAGE}

    @extend_schema(operation_id="tags_save", request=TagSave, responses=TagSerializer)
    def put(self, request: Request, tag_id: UUID) -> Response:
        data = TagSave(data=request.data)
        data.is_valid(raise_exception=True)
        row = services.save_tag(actor=session_of(request).user, tag=_tag(tag_id), **data.validated_data)
        return Response(TagSerializer(row).data)


class TagMergeView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _MANAGE}

    class TagMerge(serializers.Serializer[Any]):
        target = serializers.UUIDField()

    @extend_schema(operation_id="tags_merge", request=TagMerge, responses={204: None})
    def post(self, request: Request, tag_id: UUID) -> Response:
        data = self.TagMerge(data=request.data)
        data.is_valid(raise_exception=True)
        services.merge_tag(
            actor=session_of(request).user,
            source=_tag(tag_id),
            target=_tag(data.validated_data["target"]),
        )
        return Response(status=204)


# ---- stories, regions ------------------------------------------------------------
class StorySerializer(serializers.ModelSerializer[Story]):
    posts = serializers.IntegerField(source="post_count", read_only=True, default=0)

    class Meta:
        model = Story
        fields = [
            "id",
            "slug",
            "title_sw",
            "title_en",
            "summary_sw",
            "summary_en",
            "is_active",
            "posts",
        ]


class StorySave(serializers.Serializer[Any]):
    title_sw = serializers.CharField(max_length=160)
    title_en = serializers.CharField(max_length=160)
    slug = serializers.SlugField(max_length=120, allow_blank=True, default="")
    summary_sw = serializers.CharField(max_length=600, allow_blank=True, default="")
    summary_en = serializers.CharField(max_length=600, allow_blank=True, default="")
    is_active = serializers.BooleanField(default=True)


class StoryListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _READ, "POST": _MANAGE}

    @extend_schema(
        operation_id="stories_list",
        parameters=[OpenApiParameter("q", str), OpenApiParameter("cursor", str)],
        responses=page_of(StorySerializer),
    )
    def get(self, request: Request) -> Response:
        rows = Story.objects.annotate(post_count=Count("posts"))
        if v := request.query_params.get("q", "").strip()[:80]:
            rows = rows.filter(Q(title_sw__icontains=v) | Q(title_en__icontains=v))
        pages = TimeCursorPagination()
        page = pages.paginate_queryset(rows, request, view=self)
        return pages.get_paginated_response(StorySerializer(page, many=True).data)

    @extend_schema(operation_id="stories_create", request=StorySave, responses={201: StorySerializer})
    def post(self, request: Request) -> Response:
        data = StorySave(data=request.data)
        data.is_valid(raise_exception=True)
        row = services.save_story(actor=session_of(request).user, story=None, **data.validated_data)
        return Response(StorySerializer(row).data, status=201)


class StoryView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"PUT": _MANAGE}

    @extend_schema(operation_id="stories_save", request=StorySave, responses=StorySerializer)
    def put(self, request: Request, story_id: UUID) -> Response:
        data = StorySave(data=request.data)
        data.is_valid(raise_exception=True)
        row = Story.objects.filter(pk=story_id).first()
        if row is None:
            raise NotFound("Not found")
        row = services.save_story(actor=session_of(request).user, story=row, **data.validated_data)
        return Response(StorySerializer(row).data)


class RegionSerializer(serializers.ModelSerializer[Region]):
    class Meta:
        model = Region
        fields = ["id", "slug", "name_sw", "name_en"]


class RegionListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _READ, "POST": _MANAGE}

    class RegionSave(serializers.Serializer[Any]):
        name_sw = serializers.CharField(max_length=80)
        name_en = serializers.CharField(max_length=80)

    @extend_schema(operation_id="regions_list", responses=RegionSerializer(many=True))
    def get(self, request: Request) -> Response:
        return Response(RegionSerializer(Region.objects.order_by("name_sw"), many=True).data)

    @extend_schema(operation_id="regions_create", request=RegionSave, responses={201: RegionSerializer})
    def post(self, request: Request) -> Response:
        data = self.RegionSave(data=request.data)
        data.is_valid(raise_exception=True)
        row = services.save_region(actor=session_of(request).user, region=None, **data.validated_data)
        return Response(RegionSerializer(row).data, status=201)
