"""OpenTelemetry and Sentry start from the environment so they still work when the database is down."""

import os
from typing import Any

from newsplatform.common.logging import REDACTED, redact


def _scrub(event: Any, _: Any) -> Any:
    return redact(event)


_URLS = ("url.full", "http.url", "http.target", "url.path")


def strip_query(span: Any) -> None:
    """Query values are personal (searches) or secret (codes, cursors): traces keep the path only."""
    attributes = dict(span.attributes or {})
    for name in _URLS:
        value = attributes.get(name)
        if isinstance(value, str) and "?" in value:
            span.set_attribute(name, value.partition("?")[0])
    if attributes.get("url.query"):
        span.set_attribute("url.query", REDACTED)


def init(component: str) -> None:
    if dsn := os.environ.get("SENTRY_DSN"):
        import sentry_sdk

        sentry_sdk.init(
            dsn=dsn,
            environment=os.environ.get("ENVIRONMENT"),
            # SDK 3 collects most categories by default; locals and bodies can hold passwords.
            data_collection={
                "user_info": False,
                "http_bodies": [],
                "cookies": {"mode": "off"},
                "url_query_params": {"mode": "off"},
                "database_query_data": False,
                "stack_frame_variables": False,
            },
            release=os.environ.get("RELEASE"),
            before_send=_scrub,
        )
    if os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT"):
        from opentelemetry import trace
        from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
        from opentelemetry.instrumentation.celery import CeleryInstrumentor
        from opentelemetry.instrumentation.django import DjangoInstrumentor
        from opentelemetry.instrumentation.psycopg import PsycopgInstrumentor
        from opentelemetry.instrumentation.redis import RedisInstrumentor
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor

        provider = TracerProvider(resource=Resource.create({"service.name": f"newsplatform-{component}"}))
        provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
        trace.set_tracer_provider(provider)
        # The URL is recorded after the span starts, so it is cleaned when the response is known.
        DjangoInstrumentor().instrument(response_hook=lambda span, request, response: strip_query(span))
        for instrumentor in (CeleryInstrumentor, PsycopgInstrumentor, RedisInstrumentor):
            instrumentor().instrument()
