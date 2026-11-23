from django.urls import path

from newsplatform.common import health

urlpatterns = [
    path("health/live", health.live),
    path("health/ready", health.ready_realtime),
]
