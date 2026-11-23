"""Single-use tickets that carry the HTTP request's full session check over to a WebSocket (ADR-0020)."""

import hashlib
import secrets

import redis

from newsplatform.common.errors import ServiceUnavailable
from newsplatform.common.redis import cache
from newsplatform.staff_security.models import StaffSession

TTL_SECONDS = 30


def _key(ticket: str) -> str:
    return "ws:ticket:" + hashlib.sha256(ticket.encode()).hexdigest()


def issue(session: StaffSession) -> str:
    ticket = secrets.token_urlsafe(32)
    try:
        cache().set(_key(ticket), str(session.pk), ex=TTL_SECONDS)
    except redis.RedisError as exc:
        raise ServiceUnavailable("Realtime is unavailable") from exc
    return ticket


def consume(ticket: str) -> str | None:
    """The session id, once."""
    try:
        value: str | None = cache().getdel(_key(ticket))
    except redis.RedisError:
        return None
    return value
