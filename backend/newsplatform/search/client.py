"""A small OpenSearch client: JSON and bulk requests, IAM-signed on AWS, bounded, with a circuit breaker
(ADR-0049).

No SDK: the engine's REST API is all we use, and httpx and botocore are already here."""

from __future__ import annotations

import json
import threading
import time
from typing import Any

import httpx
from django.conf import settings

READ_TIMEOUT = 1.5  # seconds: a reader waits no longer before the fallback answers
WRITE_TIMEOUT = 30.0


class EngineError(Exception):
    """The engine could not answer (unreachable, timed out, 5xx, or the breaker is open)."""


class Breaker:
    """Opens after `limit` failures within `window` seconds; stays open `cool` seconds; then lets one try
    through."""

    def __init__(self, limit: int = 3, window: float = 30.0, cool: float = 30.0) -> None:
        self.limit, self.window, self.cool = limit, window, cool
        self._failures: list[float] = []
        self._opened = 0.0
        self._lock = threading.Lock()

    def allow(self) -> bool:
        with self._lock:
            return not self._opened or time.monotonic() - self._opened >= self.cool

    def success(self) -> None:
        with self._lock:
            self._failures.clear()
            self._opened = 0.0

    def failure(self) -> None:
        now = time.monotonic()
        with self._lock:
            self._failures = [t for t in self._failures if now - t < self.window] + [now]
            if len(self._failures) >= self.limit:
                self._opened = now


breaker = Breaker()


def configured() -> bool:
    return bool(settings.OPENSEARCH_URL)


def _sign(request: httpx.Request) -> None:
    import boto3
    from botocore.auth import SigV4Auth
    from botocore.awsrequest import AWSRequest

    credentials = boto3.Session().get_credentials()
    if credentials is None:
        raise EngineError("No AWS credentials to sign the request")
    aws = AWSRequest(method=request.method, url=str(request.url), data=request.content, headers={})
    aws.headers["Content-Type"] = request.headers.get("Content-Type", "application/json")
    SigV4Auth(credentials.get_frozen_credentials(), "es", settings.AWS_REGION).add_auth(aws)
    request.headers.update(dict(aws.headers.items()))


_clients: dict[float, httpx.Client] = {}


def _client(timeout: float) -> httpx.Client:
    if timeout not in _clients:
        _clients[timeout] = httpx.Client(
            base_url=settings.OPENSEARCH_URL.rstrip("/"),
            timeout=httpx.Timeout(timeout, connect=min(timeout, 1.0)),
            limits=httpx.Limits(max_connections=50, max_keepalive_connections=20),
        )
    return _clients[timeout]


def call(
    method: str,
    path: str,
    body: Any = None,
    *,
    ndjson: list[dict[str, Any]] | None = None,
    read: bool = True,
    ok: tuple[int, ...] = (),
) -> Any:
    """`read`: a reader is waiting (short timeout, breaker applies). `ok`: statuses that are answers, not
    errors."""
    if not configured():
        raise EngineError("OPENSEARCH_URL is not set")
    if read and not breaker.allow():
        raise EngineError("The breaker is open")
    if ndjson is not None:
        content = "".join(
            json.dumps(line, separators=(",", ":"), ensure_ascii=False) + "\n" for line in ndjson
        )
        headers = {"Content-Type": "application/x-ndjson"}
    else:
        content = "" if body is None else json.dumps(body, separators=(",", ":"), ensure_ascii=False)
        headers = {"Content-Type": "application/json"}
    client = _client(READ_TIMEOUT if read else WRITE_TIMEOUT)
    request = client.build_request(method, path, content=content.encode(), headers=headers)
    if settings.OPENSEARCH_SIGV4:
        _sign(request)
    try:
        response = client.send(request)
    except httpx.HTTPError as e:
        if read:
            breaker.failure()
        raise EngineError(f"{method} {path}: {type(e).__name__}") from e
    if response.status_code >= 500 or (response.status_code >= 400 and response.status_code not in ok):
        if read and response.status_code >= 500:
            breaker.failure()
        raise EngineError(f"{method} {path}: {response.status_code} {response.text[:300]}")
    if read:
        breaker.success()
    return response.json() if response.content else None
