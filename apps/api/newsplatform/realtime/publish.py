"""Producers call `changed()`. It carries no data: clients refetch through the permission-checked REST API."""

import uuid

import structlog
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from django.db import transaction

from newsplatform.realtime.topics import Topic

log = structlog.get_logger(__name__)


def _send(topic: Topic) -> None:
    layer = get_channel_layer()
    if layer is None:
        return
    try:
        async_to_sync(layer.group_send)(topic.group, {"type": "topic.changed", "topic": str(topic)})
    except Exception as exc:
        # A lost signal costs freshness, never correctness: clients also poll slowly.
        log.warning("realtime_publish_failed", topic=topic.kind, error=type(exc).__name__)


def changed(kind: str, ident: uuid.UUID) -> None:
    """Sent after commit, so a client that refetches at once sees the change."""
    transaction.on_commit(lambda: _send(Topic(kind, ident)), robust=True)
