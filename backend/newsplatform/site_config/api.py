from typing import Any, ClassVar

from django.http import HttpRequest, JsonResponse
from django.views.decorators.http import require_safe
from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response
from rest_framework.views import APIView

from newsplatform.common.api import StaffView, schema
from newsplatform.rbac.permissions import PublicEndpoint
from newsplatform.site_config import services
from newsplatform.site_config.brand_api import IdentitySerializer, ThemeSerializer
from newsplatform.staff_security.authentication import session_of


class PublicConfigView(APIView):
    authentication_classes = []
    permission_classes = [PublicEndpoint]

    @extend_schema(
        operation_id="site_config",
        auth=[],
        responses=schema(
            "SiteConfig",
            version=serializers.CharField(),
            media_base_url=serializers.CharField(allow_blank=True),
            identity=IdentitySerializer,
            theme=ThemeSerializer,
            localization=schema(
                "SiteLocalization",
                default_locale=serializers.ChoiceField(choices=["sw", "en"]),
                timezone=serializers.CharField(),
            ),
        ),
    )
    def get(self, request: Request) -> Response:
        return Response(
            services.public_config(),
            headers={"Cache-Control": "public, max-age=60, s-maxage=300, stale-while-revalidate=600"},
        )


_Platform = schema(
    "AppPlatformVersions",
    minimum=serializers.CharField(allow_blank=True),
    recommended=serializers.CharField(allow_blank=True),
    store=serializers.CharField(allow_blank=True),
)


class AppConfigView(APIView):
    """For installed apps. ETag and a short life: a kill switch must arrive within minutes."""

    authentication_classes = []
    permission_classes = [PublicEndpoint]

    @extend_schema(
        operation_id="app_config",
        auth=[],
        responses=schema(
            "AppConfig",
            version=serializers.CharField(),
            media_base_url=serializers.CharField(allow_blank=True),
            versions=schema("AppVersions", android=_Platform, ios=_Platform),
            maintenance=schema(
                "AppMaintenance",
                on=serializers.BooleanField(),
                sw=serializers.CharField(allow_blank=True),
                en=serializers.CharField(allow_blank=True),
            ),
            flags=schema("AppFlags", **{n: serializers.BooleanField() for n in services._FLAGS}),
            links=schema("AppLinks", **{n: serializers.CharField(allow_blank=True) for n in services._LINKS}),
            pinning=schema(
                "AppPinning",
                enabled=serializers.BooleanField(),
                pins=serializers.ListField(child=serializers.CharField()),
            ),
            identity=IdentitySerializer,
            theme=ThemeSerializer,
            localization=schema(
                "AppLocalization",
                default_locale=serializers.ChoiceField(choices=["sw", "en"]),
                timezone=serializers.CharField(),
            ),
        ),
    )
    def get(self, request: Request) -> Response:
        return Response(
            services.app_config(),
            headers={
                "Cache-Control": "public, max-age=60, s-maxage=120, stale-while-revalidate=600, "
                "stale-if-error=86400",
                "Surrogate-Key": "app-config brand",
            },
        )


@require_safe
def well_known(request: HttpRequest, name: str) -> JsonResponse:
    """Served here until the website exists; then it forwards these two addresses."""
    body: Any = services.asset_links() if name == "assetlinks.json" else services.apple_links()
    return JsonResponse(body, safe=False, headers={"Cache-Control": "public, max-age=300, s-maxage=3600"})


SectionBody = schema(
    "SettingsSection",
    key=serializers.CharField(),
    version=serializers.IntegerField(),
    values=serializers.DictField(),
    can_edit=serializers.BooleanField(),
)


class SettingsView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "settings.view", "PUT": "settings.view"}
    step_up: ClassVar[tuple[str, ...]] = ("PUT",)

    @extend_schema(operation_id="settings_get", responses=SectionBody)
    def get(self, request: Request, key: str) -> Response:
        from newsplatform.rbac.selectors import has_perm

        section, version = services.get_section(key)
        return Response(
            {
                "key": key,
                "version": version,
                "values": section.model_dump(),
                "can_edit": has_perm(session_of(request).user, services.permission_for(key)),
            }
        )

    class SettingsSave(serializers.Serializer[Any]):
        version = serializers.IntegerField(min_value=0)
        values = serializers.DictField()
        reason = serializers.CharField(max_length=500, allow_blank=True, default="")

    # The write permission depends on the section, so the service enforces it.
    @extend_schema(
        operation_id="settings_put",
        request=SettingsSave,
        responses=schema(
            "SettingsResult", version=serializers.IntegerField(), approval_required=serializers.BooleanField()
        ),
    )
    def put(self, request: Request, key: str) -> Response:
        data = self.SettingsSave(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        result = services.update_section(
            actor=session_of(request).user,
            key=key,
            version=d["version"],
            data=d["values"],
            reason=d["reason"],
        )
        pending = not isinstance(result, int)
        return Response({"version": d["version"] if pending else result, "approval_required": pending})
