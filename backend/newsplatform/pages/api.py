from typing import Any, ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import PersonSerializer, StaffView, schema
from newsplatform.common.errors import NotFound
from newsplatform.media.api import AssetSerializer, asset_body
from newsplatform.media.models import Asset
from newsplatform.pages import services
from newsplatform.pages.models import Page, PageKey, PageRevision
from newsplatform.seo import paths
from newsplatform.staff_security.authentication import session_of

_PERMS: dict[str, str | None] = dict.fromkeys(["GET", "PUT", "POST", "DELETE"], services.PERM)


class PageTextSerializer(serializers.Serializer[Any]):
    title = serializers.CharField(max_length=120, allow_blank=True)
    summary = serializers.CharField(max_length=300, allow_blank=True)
    body = serializers.DictField()


class PageTextsSerializer(serializers.Serializer[Any]):
    sw = PageTextSerializer(required=False)
    en = PageTextSerializer(required=False)


class PageRevisionSerializer(serializers.Serializer[Any]):
    number = serializers.IntegerField()
    note = serializers.CharField(allow_blank=True)
    author = PersonSerializer()
    created_at = serializers.DateTimeField()
    is_published = serializers.BooleanField()


class PageBriefSerializer(serializers.Serializer[Any]):
    key = serializers.ChoiceField(choices=PageKey.choices)
    path = serializers.CharField()
    version = serializers.IntegerField()
    published_number = serializers.IntegerField(allow_null=True)
    published_at = serializers.DateTimeField(allow_null=True)
    titles = serializers.DictField(child=serializers.CharField(allow_blank=True))


class PageDetailSerializer(PageBriefSerializer):
    texts = PageTextsSerializer()
    missing = serializers.ListField(child=serializers.CharField())
    assets = serializers.DictField(child=AssetSerializer())
    revisions = PageRevisionSerializer(many=True)


def _brief(page: Page, latest: PageRevision | None) -> dict[str, Any]:
    texts = latest.texts if latest else {}
    return {
        "key": page.key,
        "path": paths.page_path("sw", page.key),
        "version": page.version,
        "published_number": page.published.number if page.published else None,
        "published_at": page.published_at,
        "titles": {locale: t["title"] for locale, t in texts.items()},
    }


def _detail(page: Page) -> dict[str, Any]:
    revisions = list(page.revisions.select_related("author")[:50]) if page.version else []
    latest = revisions[0] if revisions else None
    ids = services._assets(latest) if latest else set()
    return {
        **_brief(page, latest),
        "texts": latest.texts if latest else {},
        "missing": services.problems(latest) if latest else [],
        "assets": {str(a.pk): asset_body(a) for a in Asset.objects.filter(pk__in=ids)},
        "revisions": [
            {
                "number": r.number,
                "note": r.note,
                "author": {"id": r.author_id, "display_name": r.author.display_name},
                "created_at": r.created_at,
                "is_published": r.pk == page.published_id,
            }
            for r in revisions
        ],
    }


class PageListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _PERMS

    @extend_schema(operation_id="pages_list", responses=PageBriefSerializer(many=True))
    def get(self, request: Request) -> Response:
        rows = {p.key: p for p in Page.objects.select_related("published")}
        out = []
        for key in PageKey.values:
            page = rows.get(key) or Page(key=key)
            out.append(_brief(page, page.revisions.first() if page.version else None))
        return Response(out)


class PageView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _PERMS

    @extend_schema(operation_id="pages_get", responses=PageDetailSerializer)
    def get(self, request: Request, key: str) -> Response:
        return Response(_detail(services.get(key)))

    class PageSave(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=0)
        texts = PageTextsSerializer()
        note = serializers.CharField(max_length=300, allow_blank=True, default="")

    @extend_schema(operation_id="pages_save", request=PageSave, responses=PageDetailSerializer)
    def put(self, request: Request, key: str) -> Response:
        data = self.PageSave(data=request.data)
        data.is_valid(raise_exception=True)
        services.save(actor=session_of(request).user, key=key, **data.validated_data)
        return Response(_detail(services.get(key)))


class PageRevisionView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _PERMS

    @extend_schema(
        operation_id="pages_revision",
        responses=schema("PageRevisionTexts", number=serializers.IntegerField(), texts=PageTextsSerializer()),
    )
    def get(self, request: Request, key: str, number: int) -> Response:
        row = PageRevision.objects.filter(page__key=key, number=number).first()
        if row is None:
            raise NotFound("Not found")
        return Response({"number": row.number, "texts": row.texts})


class PagePublishView(StaffView):
    perms: ClassVar[dict[str, str | None]] = _PERMS
    step_up: ClassVar[tuple[str, ...]] = ("POST", "DELETE")

    class PagePublish(serializers.Serializer[Any]):
        number = serializers.IntegerField(min_value=1)

    @extend_schema(operation_id="pages_publish", request=PagePublish, responses=PageDetailSerializer)
    def post(self, request: Request, key: str) -> Response:
        data = self.PagePublish(data=request.data)
        data.is_valid(raise_exception=True)
        services.publish(actor=session_of(request).user, key=key, number=data.validated_data["number"])
        return Response(_detail(services.get(key)))

    @extend_schema(operation_id="pages_withdraw", responses={200: PageDetailSerializer})
    def delete(self, request: Request, key: str) -> Response:
        services.withdraw(actor=session_of(request).user, key=key)
        return Response(_detail(services.get(key)))
