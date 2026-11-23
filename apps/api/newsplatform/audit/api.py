import csv
from collections.abc import Iterator
from typing import Any, ClassVar

from django.db import transaction
from django.db.models import QuerySet
from django.http import StreamingHttpResponse
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.audit.models import AuditEntry
from newsplatform.audit.services import record, verify_chain
from newsplatform.common.api import StaffView, schema
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.common.ratelimit import Limit
from newsplatform.staff_security.authentication import session_of

_FILTERS = [OpenApiParameter(n, str) for n in ("action", "actor", "target_id", "since", "until")]
_COLUMNS = [
    "seq",
    "occurred_at",
    "actor_id",
    "actor_label",
    "approved_by_id",
    "action",
    "target_type",
    "target_id",
    "target_label",
    "reason",
    "ip",
    "request_id",
    "hash",
]


class AuditSerializer(serializers.ModelSerializer[AuditEntry]):
    class Meta:
        model = AuditEntry
        fields = [
            "seq",
            "id",
            "occurred_at",
            "actor_id",
            "actor_label",
            "approved_by_id",
            "action",
            "target_type",
            "target_id",
            "target_label",
            "before",
            "after",
            "reason",
            "ip",
            "user_agent",
            "request_id",
            "prev_hash",
            "hash",
        ]


class _Page(TimeCursorPagination):
    ordering = "-seq"


def _filtered(request: Request) -> QuerySet[AuditEntry]:
    q, rows = request.query_params, AuditEntry.objects.all()
    if v := q.get("action"):
        rows = rows.filter(action__startswith=v)
    if v := q.get("actor"):
        rows = rows.filter(actor_id=v)
    if v := q.get("target_id"):
        rows = rows.filter(target_id=v)
    for name, lookup in (("since", "occurred_at__gte"), ("until", "occurred_at__lt")):
        if v := q.get(name):
            rows = rows.filter(**{lookup: serializers.DateTimeField().run_validation(v)})
    return rows


class AuditListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "audit.view"}

    @extend_schema(
        operation_id="audit_list",
        responses=page_of(AuditSerializer),
        parameters=[*_FILTERS, OpenApiParameter("cursor", str)],
    )
    def get(self, request: Request) -> Response:
        page = _Page()
        return page.get_paginated_response(
            AuditSerializer(page.paginate_queryset(_filtered(request), request, view=self), many=True).data
        )


class AuditVerifyView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "audit.view"}
    limit: ClassVar[Limit] = Limit(6, 60)

    @extend_schema(
        operation_id="audit_verify",
        request=None,
        responses=schema(
            "ChainReport",
            ok=serializers.BooleanField(),
            checked=serializers.IntegerField(),
            head_seq=serializers.IntegerField(),
            anchors_checked=serializers.IntegerField(),
            problems=serializers.ListField(child=serializers.DictField()),
        ),
    )
    def post(self, request: Request) -> Response:
        r = verify_chain()
        return Response(
            {
                "ok": r.ok,
                "checked": r.checked,
                "head_seq": r.head_seq,
                "anchors_checked": r.anchors_checked,
                "problems": r.problems,
            }
        )


def _safe(value: Any) -> str:
    """Neutralise spreadsheet formulas (CSV injection)."""
    text = str(value)
    return f"'{text}" if text[:1] in "=+-@\t\r" else text


class _Echo:
    def write(self, value: str) -> str:
        return value


class AuditExportView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": "audit.export"}
    step_up: ClassVar[tuple[str, ...]] = ("POST",)
    limit: ClassVar[Limit] = Limit(5, 300)

    @extend_schema(
        operation_id="audit_export",
        request=None,
        parameters=_FILTERS,
        responses={(200, "text/csv"): OpenApiTypes.STR},
    )
    def post(self, request: Request) -> StreamingHttpResponse:
        rows = _filtered(request).order_by("seq")
        with transaction.atomic():
            # The export is itself audited, before a single row leaves.
            record(
                actor=session_of(request).user,
                action="audit.exported",
                after={"filters": dict(request.query_params.items()), "rows": rows.count()},
            )
        writer = csv.writer(_Echo())

        def stream() -> Iterator[str]:
            yield writer.writerow(_COLUMNS)
            for row in rows.values_list(*_COLUMNS).iterator(chunk_size=1000):
                yield writer.writerow([_safe(v) for v in row])

        return StreamingHttpResponse(
            stream(),
            content_type="text/csv; charset=utf-8",
            headers={"Content-Disposition": 'attachment; filename="audit-log.csv"'},
        )
