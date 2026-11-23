"""How much work is waiting. ECS scales workers on it (ADR-0021)."""

from datetime import UTC, datetime
from functools import lru_cache
from typing import Any

from django.conf import settings

from newsplatform.common.redis import bus


def depths() -> dict[str, int]:
    """Waiting messages per queue. Running ones are excluded: workers reserve no more than they execute."""
    names = sorted(settings.CELERY_TASK_QUEUES)
    pipe = bus().pipeline(transaction=False)
    for name in names:
        pipe.llen(name)
    return dict(zip(names, pipe.execute(), strict=True))


@lru_cache
def _cloudwatch() -> Any:
    import boto3
    from botocore.config import Config

    return boto3.client(
        "cloudwatch",
        region_name=settings.AWS_REGION,
        endpoint_url=settings.AWS_ENDPOINT_URL or None,
        config=Config(connect_timeout=2, read_timeout=5, retries={"max_attempts": 2, "mode": "standard"}),
    )


def publish() -> dict[str, int]:
    found = depths()
    if settings.METRICS_NAMESPACE:
        now = datetime.now(UTC)
        _cloudwatch().put_metric_data(
            Namespace=settings.METRICS_NAMESPACE,
            MetricData=[
                {
                    "MetricName": "QueueDepth",
                    "Dimensions": [{"Name": "Queue", "Value": name}],
                    "Timestamp": now,
                    "Value": depth,
                    "Unit": "Count",
                }
                for name, depth in found.items()
            ],
        )
    return found
