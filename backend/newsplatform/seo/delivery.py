"""Tells the edge what changed. The website's revalidation webhook and the CDN purge go out together."""

import hashlib
import hmac
import json
import time
import uuid
from typing import Any

import httpx
import structlog
from django.conf import settings

from newsplatform.common.http import SafeResponse, fetch
from newsplatform.integrations.base import guarded_call
from newsplatform.integrations.services import get_active

log = structlog.get_logger(__name__)
CHUNK = 100


def sign(secret: str, timestamp: int, body: bytes) -> str:
    return hmac.new(secret.encode(), f"{timestamp}.".encode() + body, hashlib.sha256).hexdigest()


def payload(tags: list[str], pages: list[str]) -> dict[str, Any]:
    return {"id": uuid.uuid4().hex, "tags": tags, "paths": pages}


def purge(tags: list[str], pages: list[str]) -> None:
    from newsplatform.integrations.providers.web import WebConfig, invalidate

    if settings.LOCAL_WEB_ORIGIN:
        _tell_local(payload(tags, pages))
        return
    config = get_active("web", WebConfig)
    if config is None:
        log.info("purge_skipped", reason="not_configured", tags=len(tags))
        return
    # The website first, or the CDN would fetch the old page again. But a broken webhook must not also keep
    # the CDN stale; the caller retries, and doing either twice is harmless.
    try:
        for i in range(0, max(len(pages), 1), CHUNK):
            notify(config, tags if i == 0 else [], pages[i : i + CHUNK])
    finally:
        with guarded_call("web", "cdn.purge"):
            invalidate(config, tags, pages)


# The website's own default outside production (web/lib/env.ts).
LOCAL_SECRET = "local-dev-only-local-dev-only-local"  # noqa: S105


def _tell_local(message: dict[str, Any]) -> None:
    """A website on this machine, which the safe client rightly refuses to reach. Refused when deployed."""
    now, body = int(time.time()), json.dumps(message, separators=(",", ":")).encode()
    httpx.post(
        f"{settings.LOCAL_WEB_ORIGIN}/api/revalidate",
        content=body,
        headers={"x-timestamp": str(now), "x-signature": sign(LOCAL_SECRET, now, body)},
        timeout=5,
    ).raise_for_status()


def post_signed(config: Any, message: dict[str, Any], now: int) -> SafeResponse:
    body = json.dumps(message, separators=(",", ":")).encode()
    return fetch(
        "POST",
        f"https://{config.host}/api/revalidate",
        content=body,
        headers={
            "content-type": "application/json",
            "x-timestamp": str(now),
            "x-signature": sign(config.secret.get_secret_value(), now, body),
        },
    )


def notify(config: Any, tags: list[str], pages: list[str]) -> None:
    with guarded_call("web", "revalidate"):
        res = post_signed(config, payload(tags, pages), int(time.time()))
        if res.status >= 300:
            raise RuntimeError(f"revalidation answered {res.status}")
