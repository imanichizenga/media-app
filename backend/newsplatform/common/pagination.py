from typing import Any
from urllib.parse import parse_qs, urlparse

from drf_spectacular.utils import inline_serializer
from rest_framework import serializers
from rest_framework.pagination import CursorPagination
from rest_framework.response import Response


class TimeCursorPagination(CursorPagination):
    """UUIDv7 ids are time ordered, so `-id` is a stable, indexed cursor.

    Returns an opaque cursor, not a URL: the host this process sees is not the one the client uses.
    """

    ordering = "-id"
    page_size = 50
    max_page_size = 100
    page_size_query_param = "page_size"

    def get_paginated_response(self, data: Any) -> Response:
        link = self.get_next_link()
        cursor = parse_qs(urlparse(link).query).get(self.cursor_query_param, [None])[0] if link else None
        return Response({"next_cursor": cursor, "results": data})


def page_of(serializer: type[serializers.BaseSerializer[Any]]) -> Any:
    return inline_serializer(
        name=f"{serializer.__name__.removesuffix('Serializer')}Page",
        fields={"next_cursor": serializers.CharField(allow_null=True), "results": serializer(many=True)},
    )
