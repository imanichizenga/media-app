"""Identity tokens from Google and Apple: signature against the provider's published keys, then the claims.

Key sets are kept in Redis for an hour and fetched again at once when a token names a key not in them
(rotation).
"""

import contextlib
import json
from dataclasses import dataclass
from typing import Any

import httpx
import redis
from joserfc import jwt
from joserfc.errors import JoseError
from joserfc.jwk import KeySet

from newsplatform.common.errors import DomainError
from newsplatform.common.redis import cache
from newsplatform.integrations.base import guarded_call

_TIMEOUT = httpx.Timeout(8.0, connect=4.0)


@dataclass(frozen=True, slots=True)
class Verified:
    subject: str
    email: str | None
    email_verified: bool
    name: str
    claims: dict[str, Any]


class InvalidToken(DomainError):
    def __init__(self, why: str) -> None:
        super().__init__(f"The sign-in could not be confirmed ({why}).", code="invalid_identity_token")


def fetch_json(provider: str, url: str) -> dict[str, Any]:
    with guarded_call(provider, f"GET {url}"):
        response = httpx.get(url, timeout=_TIMEOUT)
        response.raise_for_status()
    data: dict[str, Any] = response.json()
    return data


def _keys(provider: str, url: str, *, fresh: bool = False) -> KeySet:
    key = f"jwks:{provider}"
    raw: str | None = None
    if not fresh:
        try:
            raw = cache().get(key)
        except redis.RedisError:
            raw = None
    if raw is None:
        data = fetch_json(provider, url)
        raw = json.dumps(data)
        with contextlib.suppress(redis.RedisError):
            cache().set(key, raw, ex=3600)
    return KeySet.import_key_set(json.loads(raw))


def _truth(value: Any) -> bool:
    return value is True or str(value).lower() == "true"


def verify(
    provider: str,
    token: str,
    *,
    jwks_url: str,
    issuers: list[str],
    audiences: list[str],
    nonce: str | None = None,
) -> Verified:
    audiences = [a for a in audiences if a]
    if not token or not audiences:
        raise InvalidToken("not configured" if not audiences else "no token")
    try:
        header = jwt.decode(token, _keys(provider, jwks_url), algorithms=["RS256", "ES256"])
    except JoseError:
        # Perhaps a key the cached set does not have yet: once more with a fresh set.
        try:
            header = jwt.decode(token, _keys(provider, jwks_url, fresh=True), algorithms=["RS256", "ES256"])
        except (JoseError, ValueError) as exc:
            raise InvalidToken("signature") from exc
    except ValueError as exc:
        raise InvalidToken("format") from exc
    claims = header.claims
    try:
        jwt.JWTClaimsRegistry(
            iss={"essential": True, "values": issuers},
            aud={"essential": True, "values": audiences},
            exp={"essential": True},
            sub={"essential": True},
            leeway=60,
        ).validate(claims)
    except JoseError as exc:
        raise InvalidToken(type(exc).__name__) from exc
    if nonce is not None and claims.get("nonce") != nonce:
        raise InvalidToken("nonce")
    email = claims.get("email") or None
    return Verified(
        subject=str(claims["sub"]),
        email=str(email).lower() if email else None,
        email_verified=_truth(claims.get("email_verified")),
        name=str(claims.get("name") or "").strip()[:80],
        claims=dict(claims),
    )
