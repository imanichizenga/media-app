"""What the website's sitemaps and feeds are made of (spec §7)."""

import re
from datetime import UTC, datetime, timedelta
from typing import Any

from django.db.models import Count, Max, Q
from django.db.models.functions import TruncMonth
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.request import Request
from rest_framework.response import Response

from newsplatform.common.api import schema
from newsplatform.common.errors import NotFound
from newsplatform.content.models import PostType, Publication
from newsplatform.content.public_api import PublicView
from newsplatform.content.public_shapes import PublicImageSerializer, PublicVideoSerializer

NEWS_LIMIT = 1000  # Google's own limit
NEWS_HOURS = 48
VIDEO = (PostType.VIDEO, PostType.SHORT, PostType.YOUTUBE)


class SitemapEntrySerializer(serializers.Serializer[Any]):
    path = serializers.CharField()
    locale = serializers.CharField()
    type = serializers.CharField()
    headline = serializers.CharField()
    standfirst = serializers.CharField(allow_blank=True)
    published_at = serializers.DateTimeField()
    modified_at = serializers.DateTimeField()
    image = PublicImageSerializer(allow_null=True)
    video = PublicVideoSerializer(allow_null=True)
    youtube_id = serializers.CharField(allow_blank=True)
    duration_ms = serializers.IntegerField(allow_null=True)
    is_sensitive = serializers.BooleanField()
    translations = serializers.ListField(
        child=schema("SitemapTranslation", locale=serializers.CharField(), path=serializers.CharField())
    )


_ENTRIES = schema("SitemapEntries", results=serializers.ListField(child=SitemapEntrySerializer()))


def entry(row: Publication) -> dict[str, Any]:
    card = row.card
    return {
        "path": row.path,
        "locale": row.locale,
        "type": row.type,
        "headline": card["headline"],
        "standfirst": card["standfirst"],
        "published_at": row.published_at,
        "modified_at": row.modified_at,
        "image": card["image"],
        "video": card["video"],
        "youtube_id": card["youtube_id"],
        "duration_ms": card["duration_ms"],
        "is_sensitive": card["is_sensitive"],
        "translations": row.article["translations"],
    }


class SitemapIndexView(PublicView):
    edge_seconds = 600

    @extend_schema(
        operation_id="sitemap_index",
        auth=[],
        responses=schema(
            "SitemapIndex",
            months=serializers.ListField(
                child=schema(
                    "SitemapMonth",
                    month=serializers.CharField(),
                    count=serializers.IntegerField(),
                    modified_at=serializers.DateTimeField(),
                    videos=serializers.IntegerField(),
                )
            ),
        ),
    )
    def get(self, request: Request) -> Response:
        rows = (
            Publication.objects.annotate(month=TruncMonth("published_at", tzinfo=UTC))
            .values("month")
            .annotate(
                count=Count("pk"),
                modified_at=Max("modified_at"),
                videos=Count("pk", filter=Q(type__in=VIDEO)),
            )
            .order_by("-month")
        )
        return self.cached(
            {
                "months": [
                    {
                        "month": f"{r['month']:%Y-%m}",
                        "count": r["count"],
                        "modified_at": r["modified_at"],
                        "videos": r["videos"],
                    }
                    for r in rows
                ]
            },
            ["latest"],
        )


class SitemapMonthView(PublicView):
    edge_seconds = 600

    @extend_schema(
        operation_id="sitemap_month",
        auth=[],
        parameters=[OpenApiParameter("month", str, "path")],
        responses=_ENTRIES,
    )
    def get(self, request: Request, month: str) -> Response:
        if not re.fullmatch(r"20\d\d-(0[1-9]|1[0-2])", month):
            raise NotFound("Not found")
        year, number = int(month[:4]), int(month[5:])
        start = datetime(year, number, 1, tzinfo=UTC)
        end = datetime(year + number // 12, number % 12 + 1, 1, tzinfo=UTC)
        rows = Publication.objects.filter(published_at__gte=start, published_at__lt=end)
        found = [entry(r) for r in rows.order_by("-published_at", "pk")[:50_000]]
        if not found:
            raise NotFound("Not found")
        return self.cached({"results": found}, ["latest"])


class SitemapNewsView(PublicView):
    edge_seconds = 120

    @extend_schema(operation_id="sitemap_news", auth=[], responses=_ENTRIES)
    def get(self, request: Request) -> Response:
        since = timezone.now() - timedelta(hours=NEWS_HOURS)
        rows = Publication.objects.filter(published_at__gte=since).order_by("-published_at", "pk")
        return self.cached({"results": [entry(r) for r in rows[:NEWS_LIMIT]]}, ["latest"])
