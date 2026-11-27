"""Readers' tokens (ADR-0050): a 10-minute access JWT and a rotating refresh token.

The access token is HS256 with a key derived from DJANGO_SECRET_KEY for this one purpose. Refresh tokens are
random,
stored hashed, used once: each use gives the next in the same family, and a used one presented again (stolen
and
replayed, or raced) revokes the whole family, so both holders must sign in again.
"""

import hashlib
import hmac
import secrets
import time
import uuid
from dataclasses import dataclass
from datetime import timedelta

from django.conf import settings
from django.db import transaction
from django.utils import timezone
from joserfc import jwt
from joserfc.errors import JoseError
from joserfc.jwk import OctKey

from newsplatform.accounts.models import RefreshToken, User
from newsplatform.common.errors import DomainError

ACCESS_SECONDS = 600
REFRESH_DAYS = 60
_ISSUER = "newsplatform:readers"


class Unauthenticated(DomainError):
    status = 401
    code = "unauthenticated"


def _key() -> OctKey:
    derived = hmac.new(settings.SECRET_KEY.encode(), b"reader-access-token-v1", hashlib.sha256).digest()
    return OctKey.import_key(derived)


def _hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


@dataclass(frozen=True, slots=True)
class Pair:
    access: str
    refresh: str
    access_expires_in: int = ACCESS_SECONDS

    def as_dict(self) -> dict[str, str | int]:
        return {"access": self.access, "refresh": self.refresh, "expires_in": self.access_expires_in}


def access_for(user: User, family: uuid.UUID) -> str:
    now = int(time.time())
    claims = {
        "iss": _ISSUER,
        "sub": str(user.pk),
        "sid": str(family),
        "iat": now,
        "exp": now + ACCESS_SECONDS,
    }
    return jwt.encode({"alg": "HS256"}, claims, _key())


def read_access(token: str) -> tuple[str, str]:
    """(user id, family) of a valid access token, or Unauthenticated."""
    try:
        decoded = jwt.decode(token, _key(), algorithms=["HS256"])
        jwt.JWTClaimsRegistry(
            iss={"essential": True, "value": _ISSUER}, exp={"essential": True}, sub={"essential": True}
        ).validate(decoded.claims)
    except (JoseError, ValueError) as exc:
        raise Unauthenticated("Sign in again.") from exc
    return str(decoded.claims["sub"]), str(decoded.claims.get("sid", ""))


def issue(user: User, *, device: str = "", ip: str | None = None, family: uuid.UUID | None = None) -> Pair:
    family = family or uuid.uuid4()
    raw = secrets.token_urlsafe(48)
    RefreshToken.objects.create(
        user=user,
        family=family,
        token_hash=_hash(raw),
        expires_at=timezone.now() + timedelta(days=REFRESH_DAYS),
        device=device[:120],
        ip=ip,
    )
    return Pair(access=access_for(user, family), refresh=raw)


def rotate(raw: str, *, device: str = "", ip: str | None = None) -> tuple[User, Pair]:
    with transaction.atomic():
        row = (
            RefreshToken.objects.select_for_update()
            .select_related("user")
            .filter(token_hash=_hash(raw or ""))
            .first()
        )
        if row is None:
            raise Unauthenticated("Sign in again.")
        now = timezone.now()
        if row.used_at or row.revoked_at:
            # Reuse: whoever holds this family now is not to be trusted. Committed before the error is raised.
            RefreshToken.objects.filter(family=row.family, revoked_at__isnull=True).update(revoked_at=now)
        elif row.expires_at <= now or not row.user.can_sign_in:
            raise Unauthenticated("Sign in again.")
        else:
            row.used_at = now
            row.save(update_fields=["used_at", "updated_at"])
            return row.user, issue(row.user, device=device or row.device, ip=ip, family=row.family)
    raise Unauthenticated("Sign in again.", code="token_reused")


def revoke(raw: str) -> None:
    row = RefreshToken.objects.filter(token_hash=_hash(raw or "")).first()
    if row:
        RefreshToken.objects.filter(family=row.family, revoked_at__isnull=True).update(
            revoked_at=timezone.now()
        )


def revoke_all(user: User) -> None:
    RefreshToken.objects.filter(user=user, revoked_at__isnull=True).update(revoked_at=timezone.now())


def family_alive(family: str) -> bool:
    return RefreshToken.objects.filter(family=family, revoked_at__isnull=True).exists()
