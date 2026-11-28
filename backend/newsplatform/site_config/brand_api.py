import base64
import binascii
import json
from typing import Any, ClassVar

from django.http import HttpRequest, HttpResponse, HttpResponseRedirect
from django.views.decorators.http import require_safe
from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import PersonSerializer, StaffView, schema
from newsplatform.common.ratelimit import Limit
from newsplatform.rbac.selectors import has_perm
from newsplatform.site_config import brand, logos
from newsplatform.site_config.models import BrandLogo, BrandLogoFile, BrandVersion
from newsplatform.site_config.services import get_brand
from newsplatform.site_config.theme.derive import CHOICES
from newsplatform.staff_security.authentication import session_of

IMMUTABLE = "public, max-age=31536000, immutable"
SHORT = "public, max-age=60, s-maxage=300, stale-while-revalidate=600"


# ---- shapes ----
class LogoSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    width = serializers.IntegerField()
    height = serializers.IntegerField()
    derived = serializers.BooleanField()
    svg = serializers.CharField(allow_blank=True)
    png = serializers.DictField(child=serializers.CharField())


class SchemesSerializer(serializers.Serializer[Any]):
    light = serializers.CharField()
    dark = serializers.CharField()


ThemeSerializer = schema(
    "SiteTheme",
    schema_version=serializers.IntegerField(),
    hash=serializers.CharField(),
    key=serializers.ChoiceField(choices=CHOICES),
    color=serializers.CharField(),
    dark_color=serializers.CharField(allow_blank=True),
    css=serializers.CharField(),
    theme_color=SchemesSerializer(),
    tokens=schema(
        "SiteThemeTokens",
        light=serializers.DictField(child=serializers.CharField()),
        dark=serializers.DictField(child=serializers.CharField()),
    ),
)
IdentitySerializer = schema(
    "SiteIdentity",
    brand_name=serializers.CharField(),
    tagline_sw=serializers.CharField(),
    tagline_en=serializers.CharField(),
    wordmark_light=LogoSerializer(allow_null=True),
    wordmark_dark=LogoSerializer(allow_null=True),
    symbol=LogoSerializer(allow_null=True),
)


class BrandIdentityInput(serializers.Serializer[Any]):
    brand_name = serializers.CharField(max_length=60)
    tagline_sw = serializers.CharField(max_length=140, allow_blank=True)
    tagline_en = serializers.CharField(max_length=140, allow_blank=True)
    wordmark_light = serializers.CharField(max_length=36, allow_blank=True)
    wordmark_dark = serializers.CharField(max_length=36, allow_blank=True)
    symbol = serializers.CharField(max_length=36, allow_blank=True)


class BrandAppearanceInput(serializers.Serializer[Any]):
    schema_version = serializers.IntegerField(default=1)
    theme = serializers.ChoiceField(choices=CHOICES)
    color = serializers.CharField(max_length=7)
    dark_color = serializers.CharField(max_length=7, allow_blank=True)


class BrandDataSerializer(serializers.Serializer[Any]):
    identity = BrandIdentityInput()
    appearance = BrandAppearanceInput()


BrandBody = schema(
    "Brand",
    version=serializers.IntegerField(),
    data=BrandDataSerializer(),
    identity=IdentitySerializer,
    theme=ThemeSerializer,
    can_edit=serializers.BooleanField(),
    approval_pending=serializers.BooleanField(),
)
Published = schema(
    "BrandPublished", version=serializers.IntegerField(), approval_required=serializers.BooleanField()
)


# ---- admin ----
class BrandView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "settings.view", "PUT": brand.PERMISSION}
    step_up: ClassVar[tuple[str, ...]] = ("PUT",)

    @extend_schema(operation_id="brand_get", responses=BrandBody)
    def get(self, request: Request) -> Response:
        current, version = get_brand()
        return Response(
            {
                "version": version,
                "data": current.model_dump(),
                "identity": brand.identity_body(current.identity),
                "theme": brand.theme_body(current.appearance),
                "can_edit": has_perm(session_of(request).user, brand.PERMISSION),
                "approval_pending": brand.waiting() is not None,
            }
        )

    class BrandPublish(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=0)
        data = BrandDataSerializer()  # type: ignore[assignment]
        note = serializers.CharField(max_length=500, allow_blank=True, default="")

    @extend_schema(operation_id="brand_publish", request=BrandPublish, responses=Published)
    def put(self, request: Request) -> Response:
        body = self.BrandPublish(data=request.data)
        body.is_valid(raise_exception=True)
        d = body.validated_data
        result = brand.publish(
            actor=session_of(request).user, data=d["data"], version=d["version"], note=d["note"]
        )
        return _published(result, d["version"])


def _published(result: Any, version: int) -> Response:
    pending = not isinstance(result, int)
    return Response({"version": version if pending else result, "approval_required": pending})


def _person(user: Any) -> dict[str, str] | None:
    return {"id": str(user.pk), "display_name": user.display_name} if user else None


class BrandVersionListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "settings.view"}

    @extend_schema(
        operation_id="brand_versions",
        responses=schema(
            "BrandVersions",
            results=serializers.ListField(
                child=schema(
                    "BrandVersion",
                    number=serializers.IntegerField(),
                    data=BrandDataSerializer(),
                    note=serializers.CharField(),
                    restored_from=serializers.IntegerField(allow_null=True),
                    published_at=serializers.DateTimeField(),
                    published_by=PersonSerializer(allow_null=True),
                    approved_by=PersonSerializer(allow_null=True),
                )
            ),
        ),
    )
    def get(self, request: Request) -> Response:
        rows = BrandVersion.objects.select_related("published_by", "approved_by").order_by("-number")[:50]
        return Response(
            {
                "results": [
                    {
                        "number": r.number,
                        "data": r.data,
                        "note": r.note,
                        "restored_from": r.restored_from,
                        "published_at": r.created_at,
                        "published_by": _person(r.published_by),
                        "approved_by": _person(r.approved_by),
                    }
                    for r in rows
                ]
            }
        )


class BrandRestoreView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": brand.PERMISSION}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    class BrandRestore(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=0)

    @extend_schema(operation_id="brand_restore", request=BrandRestore, responses=Published)
    def post(self, request: Request, number: int) -> Response:
        body = self.BrandRestore(data=request.data)
        body.is_valid(raise_exception=True)
        version = body.validated_data["version"]
        return _published(
            brand.restore(actor=session_of(request).user, number=number, version=version), version
        )


class BrandLogoView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": brand.PERMISSION}
    limit: ClassVar[Limit] = Limit(30, 600)

    class BrandLogoUpload(serializers.Serializer[Any]):
        kind = serializers.ChoiceField(choices=BrandLogo.Kind.choices)
        content = serializers.CharField(max_length=logos.MAX_BYTES * 4 // 3 + 8, help_text="Base64")

    @extend_schema(
        operation_id="brand_logo_upload",
        request=BrandLogoUpload,
        responses=schema("BrandLogoUploaded", logo=LogoSerializer(), white=LogoSerializer(allow_null=True)),
    )
    def post(self, request: Request) -> Response:
        body = self.BrandLogoUpload(data=request.data)
        body.is_valid(raise_exception=True)
        try:
            data = base64.b64decode(body.validated_data["content"], validate=True)
        except (binascii.Error, ValueError) as exc:
            raise serializers.ValidationError({"content": "Not base64"}) from exc
        logo = logos.upload(actor=session_of(request).user, kind=body.validated_data["kind"], data=data)
        white = logos.body(logo, white=True) if logo.kind == "wordmark" else None
        return Response({"logo": logos.body(logo), "white": white})


# ---- delivery: plain views, the same on both surfaces, safe to cache anywhere ----
def _headers(response: HttpResponse, cache: str) -> HttpResponse:
    response["Cache-Control"] = cache
    response["Cross-Origin-Resource-Policy"] = "cross-origin"
    response["Access-Control-Allow-Origin"] = "*"
    return response


def _missing() -> HttpResponse:
    return _headers(HttpResponse(status=404), "no-store")


@require_safe
def theme_css(request: HttpRequest, digest: str) -> HttpResponse:
    css = brand.stylesheet(digest)
    if css is None:
        return _missing()
    return _headers(HttpResponse(css, content_type="text/css; charset=utf-8"), IMMUTABLE)


@require_safe
def current_css(request: HttpRequest) -> HttpResponse:
    """For a page that could not learn the address in time. Pages name the hashed address instead."""
    digest = brand.css_of(get_brand()[0].appearance)[0]
    return _headers(HttpResponseRedirect(f"/theme/{digest}.css"), "no-cache")


@require_safe
def logo_file(request: HttpRequest, kind: str, digest: str, name: str) -> HttpResponse:
    row = (
        BrandLogoFile.objects.filter(logo__kind=kind, logo__digest=digest, name=name)
        .values_list("data", flat=True)
        .first()
    )
    if row is None:
        return _missing()
    response = HttpResponse(bytes(row), content_type=logos.TYPES[name.rsplit(".", 1)[-1]])
    # Opened on its own, an SVG is a page. This one can do nothing.
    response["Content-Security-Policy"] = "default-src 'none'; img-src data:; sandbox"
    return _headers(response, IMMUTABLE)


@require_safe
def icon(request: HttpRequest) -> HttpResponse:
    response = HttpResponse(brand.icon_svg(request.GET.get("maskable") == "1"), content_type="image/svg+xml")
    response["Content-Security-Policy"] = "default-src 'none'; style-src 'unsafe-inline'; sandbox"
    return _headers(response, SHORT)


@require_safe
def manifest(request: HttpRequest, locale: str) -> HttpResponse:
    text = json.dumps(brand.manifest(locale), ensure_ascii=False)
    return _headers(HttpResponse(text, content_type="application/manifest+json"), SHORT)
