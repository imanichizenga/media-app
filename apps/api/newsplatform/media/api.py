from typing import Any, ClassVar
from uuid import UUID

from django.db.models import Q
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import PersonSerializer, StaffView, schema
from newsplatform.common.errors import NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.common.ratelimit import Limit
from newsplatform.media import services, youtube
from newsplatform.media.models import Asset, AssetStatus, Kind
from newsplatform.media.storage import base_url
from newsplatform.staff_security.authentication import session_of

_UP = "media.upload"


class AssetSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    kind = serializers.ChoiceField(choices=Kind.choices)
    status = serializers.ChoiceField(choices=AssetStatus.choices)
    filename = serializers.CharField()
    bytes = serializers.IntegerField()
    mime = serializers.CharField()
    width = serializers.IntegerField(allow_null=True)
    height = serializers.IntegerField(allow_null=True)
    duration_ms = serializers.IntegerField(allow_null=True)
    alt_sw = serializers.CharField()
    alt_en = serializers.CharField()
    credit = serializers.CharField()
    license = serializers.CharField()
    focal_x = serializers.IntegerField()
    focal_y = serializers.IntegerField()
    blurhash = serializers.CharField()
    dominant_color = serializers.CharField()
    error_code = serializers.CharField()
    created_at = serializers.DateTimeField()
    uploaded_by = PersonSerializer(allow_null=True)
    thumb_url = serializers.CharField(allow_blank=True)
    large_url = serializers.CharField(allow_blank=True)
    hls_url = serializers.CharField(allow_blank=True)


def asset_body(asset: Asset) -> dict[str, Any]:
    """With full addresses: the admin shows it as is. Nothing is linked before it is scanned and processed."""
    base, out = base_url(), asset.outputs
    sizes = out.get("variants", {}).get("webp", {})
    widths = sorted(sizes, key=int)
    thumb = next((sizes[w] for w in widths if int(w) >= 320), sizes[widths[-1]] if widths else "")
    large = next((sizes[w] for w in widths if int(w) >= 1280), sizes[widths[-1]] if widths else "")
    poster = out.get("poster", "")
    ready = asset.status == AssetStatus.READY
    hls = out.get("hls", "")
    names = [
        "kind", "status", "filename", "bytes", "mime", "width", "height", "duration_ms", "alt_sw", "alt_en",
        "credit", "license", "focal_x", "focal_y", "blurhash", "dominant_color", "error_code",
    ]  # fmt: skip
    return {
        "id": str(asset.pk),
        **{n: getattr(asset, n) for n in names},
        "created_at": asset.created_at.isoformat(),
        "uploaded_by": {"id": str(u.pk), "display_name": u.display_name}
        if (u := asset.uploaded_by)
        else None,
        "thumb_url": f"{base}/{thumb or poster}" if ready and (thumb or poster) else "",
        "large_url": f"{base}/{large or poster}" if ready and (large or poster) else "",
        "hls_url": f"{base}/{hls}" if ready and hls else "",
    }


def _get(asset_id: UUID) -> Asset:
    asset = Asset.objects.select_related("uploaded_by").filter(pk=asset_id, deleted_at=None).first()
    if asset is None:
        raise NotFound("Not found")
    return asset


class _Page(TimeCursorPagination):
    page_size = 48


class AssetListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _UP}

    @extend_schema(
        operation_id="media_list",
        parameters=[OpenApiParameter(n, str) for n in ("kind", "status", "q", "cursor")]
        + [OpenApiParameter("mine", bool)],
        responses=page_of(AssetSerializer),
    )
    def get(self, request: Request) -> Response:
        q = request.query_params
        rows = Asset.objects.filter(deleted_at=None).select_related("uploaded_by")
        if q.get("kind") in Kind.values:
            rows = rows.filter(kind=q["kind"])
        if q.get("status") in AssetStatus.values:
            rows = rows.filter(status=q["status"])
        if q.get("mine") == "true":
            rows = rows.filter(uploaded_by=session_of(request).user)
        if v := q.get("q", "").strip()[:100]:
            rows = rows.filter(
                Q(filename__icontains=v) | Q(alt_sw__icontains=v) | Q(alt_en__icontains=v)
                | Q(credit__icontains=v)
            )  # fmt: skip
        pages = _Page()
        page = pages.paginate_queryset(rows, request, view=self) or []
        return pages.get_paginated_response(AssetSerializer([asset_body(a) for a in page], many=True).data)


class UploadListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _UP}
    limit = Limit(120, 60)

    class UploadBegin(serializers.Serializer[Any]):
        kind = serializers.ChoiceField(choices=Kind.choices)
        filename = serializers.CharField(max_length=300)
        size = serializers.IntegerField(min_value=1)

    @extend_schema(
        operation_id="media_begin",
        request=UploadBegin,
        responses={
            201: schema(
                "Upload",
                asset=AssetSerializer(),
                part_size=serializers.IntegerField(),
                part_count=serializers.IntegerField(),
            )
        },
    )
    def post(self, request: Request) -> Response:
        data = self.UploadBegin(data=request.data)
        data.is_valid(raise_exception=True)
        asset = services.begin_upload(actor=session_of(request).user, **data.validated_data)
        return Response(
            {
                "asset": AssetSerializer(asset_body(asset)).data,
                "part_size": asset.part_size,
                "part_count": services.part_count(asset),
            },
            status=201,
        )


class UploadPartsView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _UP, "POST": _UP}
    limit = Limit(600, 60)

    @extend_schema(
        operation_id="media_parts",
        responses=schema("UploadedParts", parts=serializers.ListField(child=serializers.IntegerField())),
    )
    def get(self, request: Request, asset_id: UUID) -> Response:
        return Response({"parts": services.uploaded_parts(actor=session_of(request).user, asset_id=asset_id)})

    class SignParts(serializers.Serializer[Any]):
        numbers = serializers.ListField(
            child=serializers.IntegerField(min_value=1), min_length=1, max_length=services.SIGN_BATCH
        )

    @extend_schema(
        operation_id="media_sign",
        request=SignParts,
        responses=schema("SignedParts", urls=serializers.DictField(child=serializers.CharField())),
    )
    def post(self, request: Request, asset_id: UUID) -> Response:
        data = self.SignParts(data=request.data)
        data.is_valid(raise_exception=True)
        urls = services.sign_parts(
            actor=session_of(request).user, asset_id=asset_id, numbers=data.validated_data["numbers"]
        )
        return Response({"urls": {str(n): u for n, u in urls.items()}})


class UploadCompleteView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _UP, "DELETE": _UP}

    @extend_schema(operation_id="media_complete", request=None, responses=AssetSerializer)
    def post(self, request: Request, asset_id: UUID) -> Response:
        asset = services.complete_upload(actor=session_of(request).user, asset_id=asset_id)
        return Response(AssetSerializer(asset_body(asset)).data)

    @extend_schema(operation_id="media_cancel", responses={204: None})
    def delete(self, request: Request, asset_id: UUID) -> Response:
        services.cancel_upload(actor=session_of(request).user, asset_id=asset_id)
        return Response(status=204)


class AssetView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": _UP, "PATCH": _UP, "DELETE": _UP}
    step_up: ClassVar[tuple[str, ...]] = ("DELETE",)

    @extend_schema(
        operation_id="media_get",
        responses=schema(
            "AssetDetail",
            asset=AssetSerializer(),
            posts=serializers.ListField(
                child=schema("AssetUse", id=serializers.UUIDField(), headline=serializers.CharField())
            ),
            elsewhere=serializers.ListField(child=serializers.CharField()),
            error_detail=serializers.CharField(),
        ),
    )
    def get(self, request: Request, asset_id: UUID) -> Response:
        from newsplatform.content.models import PostText

        asset = _get(asset_id)
        ids = services.usage(asset)
        heads = dict(
            PostText.objects.filter(post_id__in=ids).order_by("locale").values_list("post_id", "headline")
        )
        return Response(
            {
                "asset": AssetSerializer(asset_body(asset)).data,
                "posts": [{"id": i, "headline": heads.get(i, "")} for i in ids],
                "elsewhere": services.elsewhere(asset),
                "error_detail": asset.error_detail,
            }
        )

    class AssetSave(serializers.Serializer[Any]):
        alt_sw = serializers.CharField(max_length=500, allow_blank=True, required=False)
        alt_en = serializers.CharField(max_length=500, allow_blank=True, required=False)
        credit = serializers.CharField(max_length=200, allow_blank=True, required=False)
        license = serializers.CharField(max_length=200, allow_blank=True, required=False)
        focal_x = serializers.IntegerField(min_value=0, max_value=1000, required=False)
        focal_y = serializers.IntegerField(min_value=0, max_value=1000, required=False)

    @extend_schema(operation_id="media_save", request=AssetSave, responses=AssetSerializer)
    def patch(self, request: Request, asset_id: UUID) -> Response:
        data = self.AssetSave(data=request.data)
        data.is_valid(raise_exception=True)
        asset = services.update(actor=session_of(request).user, asset_id=asset_id, data=data.validated_data)
        return Response(AssetSerializer(asset_body(asset)).data)

    @extend_schema(operation_id="media_delete", responses={204: None})
    def delete(self, request: Request, asset_id: UUID) -> Response:
        services.delete(actor=session_of(request).user, asset_id=asset_id)
        return Response(status=204)


class AssetRetryView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _UP}

    @extend_schema(operation_id="media_retry", request=None, responses=AssetSerializer)
    def post(self, request: Request, asset_id: UUID) -> Response:
        asset = services.retry(actor=session_of(request).user, asset_id=asset_id)
        return Response(AssetSerializer(asset_body(asset)).data)


class YouTubeView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": _UP}
    limit = Limit(30, 60)

    class YouTubeRequest(serializers.Serializer[Any]):
        url = serializers.CharField(max_length=2048)

    @extend_schema(
        operation_id="media_youtube",
        request=YouTubeRequest,
        responses=schema(
            "YouTubeVideo",
            video_id=serializers.CharField(),
            title=serializers.CharField(),
            author=serializers.CharField(),
            start=serializers.IntegerField(),
            vertical=serializers.BooleanField(),
            thumbnail=AssetSerializer(allow_null=True),
        ),
    )
    def post(self, request: Request) -> Response:
        data = self.YouTubeRequest(data=request.data)
        data.is_valid(raise_exception=True)
        found = youtube.import_video(actor=session_of(request).user, url=data.validated_data["url"])
        thumb = found.pop("thumbnail")
        return Response({**found, "thumbnail": AssetSerializer(asset_body(thumb)).data if thumb else None})
