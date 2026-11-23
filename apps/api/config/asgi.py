import os

from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")
application = get_asgi_application()

from newsplatform.common.telemetry import init  # noqa: E402

init("api")
