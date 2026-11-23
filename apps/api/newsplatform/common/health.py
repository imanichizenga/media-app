import redis
from django.db import DatabaseError, connection
from django.http import HttpRequest, JsonResponse

from newsplatform.common.redis import cache


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
