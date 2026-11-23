import structlog
from celery import shared_task

from newsplatform.ops import queues

log = structlog.get_logger(__name__)


@shared_task
def publish_queue_depths() -> None:
    log.info("queue_depths", **{f"queue_{name}": depth for name, depth in queues.publish().items()})
