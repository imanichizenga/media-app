"""What unit tests can hold still. support/scripts/verify-otel.sh proves the rest against a real collector."""

import importlib

import pytest

from newsplatform.common import telemetry


class Span:
    def __init__(self, **attributes):
        self.attributes = attributes

    def set_attribute(self, name, value):
        self.attributes[name] = value


def test_query_values_never_reach_a_trace():
    span = Span(
        **{
            "http.target": "/api/v1/search?q=my+illness",
            "http.url": "https://api.example/api/v1/x?code=abc",
            "url.full": "https://api.example/api/v1/x?code=abc",
            "url.query": "code=abc",
            "url.path": "/api/v1/x",
            "http.method": "GET",
        }
    )
    telemetry.strip_query(span)
    assert "abc" not in str(span.attributes)
    assert "illness" not in str(span.attributes)
    assert span.attributes["http.target"] == "/api/v1/search"
    assert span.attributes["url.path"] == "/api/v1/x"


def test_spans_without_attributes_are_fine():
    span = Span()
    span.attributes = None
    telemetry.strip_query(span)


@pytest.mark.parametrize("module", ["config.asgi", "config.asgi_realtime"])
def test_telemetry_starts_before_django_reads_its_middleware(monkeypatch, module):
    """The other way round exports no HTTP span at all, silently."""
    order = []
    import django.core.asgi

    real = django.core.asgi.get_asgi_application
    monkeypatch.setattr(telemetry, "init", lambda component: order.append("telemetry"))
    monkeypatch.setattr(django.core.asgi, "get_asgi_application", lambda: (order.append("django"), real())[1])
    importlib.reload(importlib.import_module(module))
    assert order[-2:] == ["telemetry", "django"]


def test_asgi_instrumentation_is_installed():
    """Without it the Django instrumentation ignores every ASGI request, silently."""
    importlib.import_module("opentelemetry.instrumentation.asgi")
