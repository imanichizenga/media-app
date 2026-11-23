import os

from celery import Celery
from celery.signals import worker_process_init

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.production")
app = Celery("newsplatform")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()


@worker_process_init.connect
def _init(**_: object) -> None:
    from newsplatform.common.telemetry import init

    init("worker")
