import redis
from django.db import DatabaseError, connection
from django.http import HttpRequest, JsonResponse

from newsplatform.common.redis import bus, cache


def live(_: HttpRequest) -> JsonResponse:
    return JsonResponse({"status": "ok"})


def ready(_: HttpRequest) -> JsonResponse:
    checks = {"database": True, "redis": True}
    try:
        with connection.cursor() as cur:
            cur.execute("SELECT 1")
    except DatabaseError:
        checks["database"] = False
    try:
        cache().ping()
    except redis.RedisError:
        checks["redis"] = False
    return JsonResponse(
        {"status": "ok" if all(checks.values()) else "degraded", "checks": checks},
        status=200 if checks["database"] else 503,
    )


def ready_realtime(_: HttpRequest) -> JsonResponse:
    """A socket server without the channel layer can accept connections but never deliver: take it out."""
    checks = {"database": True, "channel_layer": True}
    try:
        with connection.cursor() as cur:
            cur.execute("SELECT 1")
    except DatabaseError:
        checks["database"] = False
    try:
        bus().ping()
    except redis.RedisError:
        checks["channel_layer"] = False
    ok = all(checks.values())
    return JsonResponse({"status": "ok" if ok else "degraded", "checks": checks}, status=200 if ok else 503)
