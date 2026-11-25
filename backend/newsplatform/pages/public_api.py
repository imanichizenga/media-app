from typing import Any

from drf_spectacular.utils import extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import schema
from newsplatform.content.public_api import _LOCALE, PublicView, locale_of
from newsplatform.pages import services

PublicPageLink = schema(
    "PublicPageLink",
    key=serializers.CharField(),
    title=serializers.CharField(),
    path=serializers.CharField(),
    modified_at=serializers.DateTimeField(),
)


class PublicPageSerializer(serializers.Serializer[Any]):
    key = serializers.CharField()
    locale = serializers.CharField()
    path = serializers.CharField()
    title = serializers.CharField()
    summary = serializers.CharField(allow_blank=True)
    body = serializers.DictField()
    assets = serializers.DictField(child=serializers.DictField())
    published_at = serializers.DateTimeField()
    modified_at = serializers.DateTimeField()
    translations = serializers.ListField(
        child=schema("PageTranslation", locale=serializers.CharField(), path=serializers.CharField())
    )


class PublicPageListView(PublicView):
    edge_seconds = 3600

    @extend_schema(
        operation_id="pages",
        auth=[],
        parameters=[_LOCALE],
        responses=schema("PublicPages", results=serializers.ListField(child=PublicPageLink)),
    )
    def get(self, request: Request) -> Response:
        return self.cached({"results": services.listed(locale_of(request))}, ["pages"])


class PublicPageView(PublicView):
    edge_seconds = 3600

    @extend_schema(operation_id="page", auth=[], parameters=[_LOCALE], responses=PublicPageSerializer)
    def get(self, request: Request, key: str) -> Response:
        return self.cached(services.public(locale_of(request), key), ["pages", f"page-{key}"])
