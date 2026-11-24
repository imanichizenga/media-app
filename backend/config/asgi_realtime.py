"""The WebSocket deployment: staff sockets and health checks, no API routes (ADR-0020)."""

import os
from typing import Any

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")
os.environ.setdefault("API_SURFACE", "realtime")

from newsplatform.common.telemetry import init

init("realtime")

from django.core.asgi import get_asgi_application  # noqa: E402

http = get_asgi_application()

from channels.routing import ProtocolTypeRouter, URLRouter  # noqa: E402
from django.urls import path  # noqa: E402

from newsplatform.realtime.consumers import StaffConsumer  # noqa: E402

# Channels accepts an ASGI application as a view; Django's own stubs for `path` do not know that.
staff: Any = StaffConsumer.as_asgi()
routes: list[Any] = [path("ws/v1/staff", staff)]
application = ProtocolTypeRouter({"http": http, "websocket": URLRouter(routes)})
