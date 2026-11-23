from functools import lru_cache
from typing import Any

import redis
from django.conf import settings
from redis.cluster import RedisCluster

_OPTS: dict[str, Any] = {"socket_connect_timeout": 1, "socket_timeout": 2, "decode_responses": True}


@lru_cache
def cache() -> Any:
    """Cache/counter Redis. Cluster mode in AWS, single node locally."""
    if settings.REDIS_CLUSTER:
        return RedisCluster.from_url(settings.REDIS_URL, **_OPTS)
    return redis.Redis.from_url(settings.REDIS_URL, **_OPTS)


@lru_cache
def bus() -> Any:
    """Non-cluster Redis used for the Celery broker and pub/sub (ADR-0014)."""
    return redis.Redis.from_url(settings.BROKER_URL, **_OPTS)
