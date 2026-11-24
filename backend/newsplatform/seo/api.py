from typing import Any, ClassVar
from uuid import UUID

from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import StaffView
from newsplatform.common.errors import NotFound
from newsplatform.common.pagination import TimeCursorPagination, page_of
from newsplatform.seo import services
from newsplatform.seo.models import Redirect
from newsplatform.staff_security.authentication import session_of


class RedirectSerializer(serializers.ModelSerializer[Redirect]):
    class Meta:
        model = Redirect
        fields = ["id", "from_path", "to_path", "is_automatic", "created_at"]


class RedirectListView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"GET": "taxonomy.manage", "POST": "taxonomy.manage"}

    @extend_schema(
        operation_id="redirects_list",
        parameters=[OpenApiParameter("q", str), OpenApiParameter("cursor", str)],
        responses=page_of(RedirectSerializer),
    )
    def get(self, request: Request) -> Response:
        rows = Redirect.objects.all()
        if v := request.query_params.get("q", "").strip()[:200]:
            rows = rows.filter(from_path__icontains=v) | rows.filter(to_path__icontains=v)
        pages = TimeCursorPagination()
        page = pages.paginate_queryset(rows, request, view=self)
        return pages.get_paginated_response(RedirectSerializer(page, many=True).data)

    class RedirectCreate(serializers.Serializer[Any]):
        from_path = serializers.CharField(max_length=400)
        to_path = serializers.CharField(max_length=400)

    @extend_schema(
        operation_id="redirects_create", request=RedirectCreate, responses={201: RedirectSerializer}
    )
    def post(self, request: Request) -> Response:
        data = self.RedirectCreate(data=request.data)
        data.is_valid(raise_exception=True)
        row = services.add_manual(actor=session_of(request).user, **data.validated_data)
        return Response(RedirectSerializer(row).data, status=201)


class RedirectView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"DELETE": "taxonomy.manage"}

    @extend_schema(operation_id="redirects_delete", responses={204: None})
    def delete(self, request: Request, redirect_id: UUID) -> Response:
        row = Redirect.objects.filter(pk=redirect_id).first()
        if row is None:
            raise NotFound("Not found")
        services.remove(actor=session_of(request).user, row=row)
        return Response(status=204)
