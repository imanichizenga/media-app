import boto3
import pytest
from celery import current_app
from kombu import Queue
from moto import mock_aws

from newsplatform.common.redis import bus
from newsplatform.ops import queues
from newsplatform.ops.tasks import publish_queue_depths


@pytest.fixture(autouse=True)
def _fresh_client():
    cached = queues._cloudwatch
    cached.cache_clear()
    yield
    cached.cache_clear()


def test_depths_count_waiting_messages_of_every_declared_queue(settings):
    bus().rpush("media", "a", "b", "c")
    found = queues.depths()
    assert found["media"] == 3
    assert found["critical"] == 0
    assert found.keys() == settings.CELERY_TASK_QUEUES.keys()


def test_counted_the_way_the_broker_stores_them():
    """Guards against a transport change that moves messages out of the list we measure."""
    before = queues.depths()["sync"]
    with current_app.connection_for_write() as conn:
        conn.Producer().publish({"n": 1}, routing_key="sync", declare=[Queue("sync")], serializer="json")
    assert queues.depths()["sync"] == before + 1


@mock_aws
def test_published_to_cloudwatch_per_queue(settings, monkeypatch):
    for name in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"):
        monkeypatch.setenv(name, "test")
    settings.METRICS_NAMESPACE = "news-test"
    bus().rpush("critical", "a", "b")
    publish_queue_depths()
    client = boto3.client("cloudwatch", region_name=settings.AWS_REGION)
    rows = client.list_metrics(Namespace="news-test", MetricName="QueueDepth")["Metrics"]
    assert {r["Dimensions"][0]["Value"] for r in rows} == set(settings.CELERY_TASK_QUEUES)


def test_nothing_is_sent_outside_aws(settings, monkeypatch):
    settings.METRICS_NAMESPACE = ""
    monkeypatch.setattr(queues, "_cloudwatch", lambda: pytest.fail("called AWS"))
    publish_queue_depths()


def test_measured_every_minute_on_a_queue_no_backlog_can_block(settings):
    entry = settings.CELERY_BEAT_SCHEDULE["queue-depths"]
    assert entry["schedule"] == 60
    assert entry["options"]["expires"] < 60
    assert settings.CELERY_TASK_ROUTES["newsplatform.ops.tasks.*"] == {"queue": "ops"}
