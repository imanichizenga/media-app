"""GCRA rate limiter: one Redis key per subject, atomic Lua, no bursts at window edges."""

import hashlib
from dataclasses import dataclass

import redis

from newsplatform.common.errors import RateLimited, ServiceUnavailable
from newsplatform.common.redis import cache

# KEYS[1]; ARGV: emission interval ms, burst tolerance ms. Uses Redis time, so app clock skew is irrelevant.
_LUA = """
local t = redis.call('TIME'); local now = t[1]*1000 + math.floor(t[2]/1000)
local interval = tonumber(ARGV[1]); local tolerance = tonumber(ARGV[2])
local tat = math.max(tonumber(redis.call('GET', KEYS[1]) or now), now)
local new = tat + interval
if new - now > tolerance then return new - now - tolerance end
redis.call('SET', KEYS[1], new, 'PX', math.max(math.ceil(new - now), 1))
return 0
"""


@dataclass(frozen=True, slots=True)
class Limit:
    count: int
    per_seconds: int


def subject_key(*parts: str) -> str:
    """Hashed so raw emails, phones and IPs never land in Redis key names."""
    return hashlib.sha256("\x1f".join(parts).encode()).hexdigest()[:32]


def check(scope: str, subject: str, limit: Limit, *, fail_closed: bool) -> None:
    interval = limit.per_seconds * 1000 / limit.count
    try:
        wait = int(cache().eval(_LUA, 1, f"rl:{scope}:{{{subject}}}", interval, limit.per_seconds * 1000))
    except redis.RedisError as exc:
        if fail_closed:
            raise ServiceUnavailable("Rate limiter unavailable") from exc
        return
    if wait > 0:
        raise RateLimited(retry_after=max(1, -(-wait // 1000)))
