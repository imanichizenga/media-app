from typing import ClassVar

from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import StaffView, schema
from newsplatform.common.ratelimit import Limit
from newsplatform.realtime import tickets
from newsplatform.staff_security.authentication import session_of


class RealtimeTicketView(StaffView):
    perms: ClassVar[dict[str, str | None]] = {"POST": None}
    limit: ClassVar[Limit] = Limit(30, 60)

    @extend_schema(
        operation_id="realtime_ticket",
        request=None,
        responses=schema("RealtimeTicket", ticket=serializers.CharField()),
    )
    def post(self, request: Request) -> Response:
        return Response({"ticket": tickets.issue(session_of(request))})
