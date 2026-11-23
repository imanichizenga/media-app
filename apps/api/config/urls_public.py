from django.urls import path

from newsplatform.common import health
from newsplatform.site_config.api import PublicConfigView

urlpatterns = [
    path("health/live", health.live),
    path("health/ready", health.ready),
    path("api/v1/site-config", PublicConfigView.as_view()),
]
