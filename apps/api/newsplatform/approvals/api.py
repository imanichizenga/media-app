from typing import Any, ClassVar

from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.approvals import services
from newsplatform.approvals.models import ApprovalRequest, ApprovalStatus
from newsplatform.common.api import PersonSerializer, StaffView
from newsplatform.common.errors import NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.staff_security.authentication import session_of


class ApprovalSerializer(serializers.ModelSerializer[ApprovalRequest]):
    requested_by = PersonSerializer()
    decided_by = PersonSerializer(allow_null=True)
    status = serializers.ChoiceField(choices=ApprovalStatus.choices)

    class Meta:
        model = ApprovalRequest
        fields = [
            "id",
            "action",
            "summary",
            "payload",
            "reason",
            "status",
            "requested_by",
            "decided_by",
            "decided_at",
            "decision_note",
            "expires_at",
            "created_at",
        ]


class NoteSerializer(serializers.Serializer[Any]):
    note = serializers.CharField(max_length=500, allow_blank=True, default="")


class ApprovalListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "approvals.decide"}

    @extend_schema(
        operation_id="approvals_list",
        responses=page_of(ApprovalSerializer),
        parameters=[OpenApiParameter("status", str), OpenApiParameter("cursor", str)],
    )
    def get(self, request: Request) -> Response:
        rows = ApprovalRequest.objects.select_related("requested_by", "decided_by")
        if status := request.query_params.get("status"):
            rows = rows.filter(status=status)
        page = TimeCursorPagination()
        return page.get_paginated_response(
            ApprovalSerializer(page.paginate_queryset(rows, request, view=self), many=True).data
        )


class ApprovalDecisionView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "approvals.decide"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)

    @extend_schema(
        operation_id="approvals_decide",
        request=NoteSerializer,
        responses=ApprovalSerializer,
        parameters=[OpenApiParameter("decision", str, OpenApiParameter.PATH, enum=["approve", "reject"])],
    )
    def post(self, request: Request, approval_id: Any, decision: str) -> Response:
        data = NoteSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        fn = services.approve if decision == "approve" else services.reject
        try:
            req = fn(actor=session_of(request).user, req_id=approval_id, note=data.validated_data["note"])
        except ApprovalRequest.DoesNotExist as exc:
            raise NotFound("Not found") from exc
        return Response(ApprovalSerializer(req).data)
