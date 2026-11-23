import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")

from newsplatform.common.telemetry import init

# Before the application exists: instrumentation adds a middleware, and Django reads the list only once.
init("api")

from django.core.asgi import get_asgi_application  # noqa: E402

application = get_asgi_application()
