from typing import Any, ClassVar

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
