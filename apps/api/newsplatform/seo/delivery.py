"""Tells the edge what changed. The website's revalidation webhook and the CDN purge go out together."""

import hashlib
import hmac
import json
import time
import uuid
from typing import Any

import structlog

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

    config = get_active("web", WebConfig)
    if config is None:
        log.info("purge_skipped", reason="not_configured", tags=len(tags))
        return
    for i in range(0, max(len(pages), 1), CHUNK):
        notify(config, tags if i == 0 else [], pages[i : i + CHUNK])
    with guarded_call("web", "cdn.purge"):
        invalidate(config, tags, pages)


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
