from typing import Any, ClassVar

from django.conf import settings
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.approvals.models import ApprovalRequest
from newsplatform.common.api import PersonSerializer, StaffView, body, schema
from newsplatform.common.errors import NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.common.ratelimit import Limit
from newsplatform.integrations import services
from newsplatform.integrations.base import STEP_STATUSES, providers
from newsplatform.integrations.models import (
    SUMMARY_STATUSES,
    IntegrationCall,
    IntegrationConfig,
    IntegrationTestRun,
    IntegrationVersion,
    RunStatus,
)
from newsplatform.staff_security.authentication import session_of


class StepSerializer(serializers.Serializer[Any]):
    key = serializers.CharField()
    label_en = serializers.CharField()
    label_sw = serializers.CharField()
    status = serializers.ChoiceField(choices=STEP_STATUSES)
    latency_ms = serializers.IntegerField()
    detail = serializers.CharField()
    remediation = serializers.CharField()
    remediation_sw = serializers.CharField(required=False)


class TestRunSerializer(serializers.ModelSerializer[IntegrationTestRun]):
    __test__ = False
    steps = StepSerializer(many=True)
    status = serializers.ChoiceField(choices=RunStatus.choices)
    version_number = serializers.IntegerField(source="version.number")
    started_by = PersonSerializer(allow_null=True)

    class Meta:
        model = IntegrationTestRun
        fields = ["id", "status", "steps", "version_number", "started_by", "created_at", "finished_at"]


class SummarySerializer(serializers.Serializer[Any]):
    provider = serializers.CharField()
    name = serializers.CharField()
    category = serializers.CharField()
    description_en = serializers.CharField()
    description_sw = serializers.CharField()
    status = serializers.ChoiceField(choices=SUMMARY_STATUSES)
    last_tested_at = serializers.DateTimeField(allow_null=True)
    last_test_passed = serializers.BooleanField(allow_null=True)


class FieldSerializer(serializers.Serializer[Any]):
    name = serializers.CharField()
    kind = serializers.ChoiceField(choices=["text", "integer", "boolean", "secret"])
    label_en = serializers.CharField()
    label_sw = serializers.CharField()
    help_en = serializers.CharField(allow_blank=True)
    help_sw = serializers.CharField(allow_blank=True)
    is_required = serializers.BooleanField()
    default = serializers.JSONField(allow_null=True)


class VersionSerializer(serializers.ModelSerializer[IntegrationVersion]):
    created_by = PersonSerializer()
    fields_ = serializers.DictField(source="fields")

    class Meta:
        model = IntegrationVersion
        # `secrets` is deliberately absent: hints only.
        fields = ["id", "number", "fields_", "secret_hints", "created_by", "created_at"]


class DetailSerializer(SummarySerializer):
    schema = FieldSerializer(many=True)
    test_params = serializers.ListField(child=serializers.CharField())
    latest = VersionSerializer(allow_null=True)
    active_number = serializers.IntegerField(allow_null=True)
    latest_test = TestRunSerializer(allow_null=True)
    history = TestRunSerializer(many=True)


def _summary(key: str, config: IntegrationConfig | None) -> dict[str, Any]:
    p = services.get_provider(key)
    return {
        "provider": key,
        "name": p.name,
        "category": p.category,
        "description_en": p.description_en,
        "description_sw": p.description_sw,
        "status": config.status if config else "unconfigured",
        "last_tested_at": config.last_tested_at if config else None,
        "last_test_passed": config.last_test_passed if config else None,
    }


def _config(key: str) -> IntegrationConfig | None:
    return (
        IntegrationConfig.objects.select_related("active_version")
        .filter(provider=key, environment=settings.ENVIRONMENT)
        .first()
    )


def _version(key: str, number: int) -> IntegrationVersion:
    row = (
        IntegrationVersion.objects.select_related("config")
        .filter(config__provider=key, config__environment=settings.ENVIRONMENT, number=number)
        .first()
    )
    if row is None:
        raise NotFound("Not found")
    return row


class IntegrationListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "integrations.view"}

    @extend_schema(operation_id="integrations_list", responses=SummarySerializer(many=True))
    def get(self, request: Request) -> Response:
        rows = {c.provider: c for c in IntegrationConfig.objects.filter(environment=settings.ENVIRONMENT)}
        return Response(SummarySerializer([_summary(k, rows.get(k)) for k in providers()], many=True).data)


class IntegrationDetailView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "integrations.view", "PUT": "integrations.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("PUT",)

    def _detail(self, key: str) -> Response:
        config, shape = _config(key), services.schema_for(services.get_provider(key))
        latest = services.latest_version(config) if config else None
        runs = (
            list(
                IntegrationTestRun.objects.filter(version__config=config)
                .select_related("version", "started_by")
                .order_by("-id")[:20]
            )
            if config
            else []
        )
        active = config.active_version if config else None
        return Response(
            DetailSerializer(
                {
                    **_summary(key, config),
                    "schema": shape["fields"],
                    "test_params": shape["test_params"],
                    "latest": latest,
                    "active_number": active.number if active else None,
                    "latest_test": next((r for r in runs if latest and r.version_id == latest.pk), None),
                    "history": runs,
                }
            ).data
        )

    @extend_schema(operation_id="integrations_get", responses=DetailSerializer)
    def get(self, request: Request, key: str) -> Response:
        return self._detail(key)

    class IntegrationSave(serializers.Serializer[Any]):
        base_number = serializers.IntegerField(min_value=0)
        fields_ = serializers.DictField()
        secrets = serializers.DictField(
            child=serializers.CharField(allow_null=True, trim_whitespace=False, max_length=20000),
            default=dict,
        )

    @extend_schema(operation_id="integrations_save", request=IntegrationSave, responses=DetailSerializer)
    def put(self, request: Request, key: str) -> Response:
        data = self.IntegrationSave(data=request.data)
        data.is_valid(raise_exception=True)
        d = data.validated_data
        services.save_draft(
            actor=session_of(request).user,
            provider_key=key,
            fields=d["fields_"],
            secrets=d["secrets"],
            base_number=d["base_number"],
        )
        return self._detail(key)


class IntegrationTestView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "integrations.manage"}
    limit: ClassVar[Limit] = Limit(20, 60)

    @extend_schema(
        operation_id="integrations_test",
        request=schema("TestRequest", params=serializers.DictField(child=serializers.CharField())),
        responses={202: TestRunSerializer},
    )
    def post(self, request: Request, key: str, number: int) -> Response:
        params = serializers.DictField(child=serializers.CharField(max_length=254)).run_validation(
            body(request).get("params", {})
        )
        run = services.start_test(
            actor=session_of(request).user, version=_version(key, number), params=params
        )
        run.refresh_from_db()
        return Response(TestRunSerializer(run).data, status=202)


class IntegrationTestRunView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "integrations.view"}

    @extend_schema(operation_id="integrations_test_run", responses=TestRunSerializer)
    def get(self, request: Request, run_id: Any) -> Response:
        run = IntegrationTestRun.objects.select_related("version", "started_by").filter(pk=run_id).first()
        if run is None:
            raise NotFound("Not found")
        return Response(TestRunSerializer(run).data)


class IntegrationActivateView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "integrations.manage"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(
        operation_id="integrations_activate",
        request=schema("ActivateRequest", override_reason=serializers.CharField(allow_blank=True)),
        responses=schema("ActivateResult", approval_required=serializers.BooleanField()),
    )
    def post(self, request: Request, key: str, number: int) -> Response:
        reason = serializers.CharField(max_length=500, allow_blank=True).run_validation(
            body(request).get("override_reason", "")
        )
        result = services.activate(
            actor=session_of(request).user, version=_version(key, number), override_reason=reason
        )
        return Response({"approval_required": isinstance(result, ApprovalRequest)})


class CallSerializer(serializers.ModelSerializer[IntegrationCall]):
    class Meta:
        model = IntegrationCall
        fields = ["id", "provider", "operation", "ok", "latency_ms", "detail", "request_id", "created_at"]


class IntegrationCallListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "logs.view"}

    @extend_schema(
        operation_id="integration_calls",
        responses=page_of(CallSerializer),
        parameters=[
            OpenApiParameter("provider", str),
            OpenApiParameter("ok", bool),
            OpenApiParameter("cursor", str),
        ],
    )
    def get(self, request: Request) -> Response:
        rows = IntegrationCall.objects.all()
        if provider := request.query_params.get("provider"):
            rows = rows.filter(provider=provider)
        if (ok := request.query_params.get("ok")) in {"true", "false"}:
            rows = rows.filter(ok=ok == "true")
        page = TimeCursorPagination()
        return page.get_paginated_response(
            CallSerializer(page.paginate_queryset(rows, request, view=self), many=True).data
        )
