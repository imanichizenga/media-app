import hashlib
import hmac
import re
import secrets
from datetime import timedelta
from uuid import UUID

from django.conf import settings
from django.db import transaction
from django.db.models import QuerySet
from django.http import HttpRequest
from django.utils import timezone

from newsplatform.accounts.models import User
from newsplatform.common import context
from newsplatform.site_config.services import get_security
from newsplatform.staff_security.events import auth_event
from newsplatform.staff_security.models import SessionStage, StaffSession

_PREAUTH_TTL = timedelta(minutes=10)
_BROWSERS = [
    ("Edg/", "Edge"),
    ("OPR/", "Opera"),
    ("Firefox/", "Firefox"),
    ("Chrome/", "Chrome"),
    ("Safari/", "Safari"),
]
_SYSTEMS = [
    ("Android", "Android"),
    ("iPhone", "iOS"),
    ("iPad", "iPadOS"),
    ("Windows", "Windows"),
    ("Mac OS X", "macOS"),
    ("CrOS", "ChromeOS"),
    ("Linux", "Linux"),
]


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def csrf_for(token: str) -> str:
    """Bound to the session token: a token from another session never validates."""
    return hmac.new(settings.SECRET_KEY.encode(), b"staff-csrf:" + token.encode(), hashlib.sha256).hexdigest()


def device_label(user_agent: str) -> str:
    browser = next((n for m, n in _BROWSERS if m in user_agent), "Unknown browser")
    system = next((n for m, n in _SYSTEMS if m in user_agent), "unknown system")
    return f"{browser} on {system}"


def fingerprint(request: HttpRequest) -> str:
    """Coarse on purpose: survives browser updates, breaks when a cookie moves to another machine."""
    ua = request.headers.get("User-Agent", "")
    platform = re.sub(r"[^A-Za-z ]", "", request.headers.get("Sec-CH-UA-Platform", ""))
    return hashlib.sha256(f"{device_label(ua)}|{platform}".encode()).hexdigest()


def create(user: User, stage: SessionStage, request: HttpRequest) -> tuple[StaffSession, str]:
    token, now, ctx = secrets.token_urlsafe(32), timezone.now(), context.current()
    session = StaffSession.objects.create(
        user=user,
        token_hash=hash_token(token),
        stage=stage,
        last_seen_at=now,
        expires_at=now + _PREAUTH_TTL,
        fingerprint=fingerprint(request),
        device_label=device_label(ctx.user_agent),
        ip=ctx.ip or "",
        country=ctx.country,
    )
    return session, token


def promote(session: StaffSession, method: str) -> str:
    """Enter the active stage under a NEW token: a pre-auth token can never become a full session."""
    token, now = secrets.token_urlsafe(32), timezone.now()
    session.token_hash, session.stage = hash_token(token), SessionStage.ACTIVE
    session.mfa_verified_at, session.mfa_method, session.mfa_failures = now, method, 0
    session.last_seen_at = now
    session.expires_at = now + timedelta(hours=get_security().absolute_timeout_hours)
    # Never a full save: this instance predates verification and would restore the consumed challenge.
    session.save(
        update_fields=[
            "token_hash",
            "stage",
            "mfa_verified_at",
            "mfa_method",
            "mfa_failures",
            "last_seen_at",
            "expires_at",
            "updated_at",
        ]
    )
    return token


def refresh_mfa(session: StaffSession, method: str) -> None:
    session.mfa_verified_at, session.mfa_method, session.mfa_failures = timezone.now(), method, 0
    session.save(update_fields=["mfa_verified_at", "mfa_method", "mfa_failures", "updated_at"])


def revoke(session: StaffSession, reason: str) -> None:
    StaffSession.objects.filter(pk=session.pk, revoked_at__isnull=True).update(
        revoked_at=timezone.now(), revoke_reason=reason
    )
    session.revoked_at = timezone.now()


def revoke_all(user: User, reason: str, *, keep: StaffSession | None = None) -> int:
    rows = StaffSession.objects.filter(user=user, revoked_at__isnull=True)
    if keep:
        rows = rows.exclude(pk=keep.pk)
    return rows.update(revoked_at=timezone.now(), revoke_reason=reason)


def _live() -> QuerySet[StaffSession]:
    return StaffSession.objects.select_related("user").filter(revoked_at__isnull=True)


def find(token: str) -> StaffSession | None:
    """Read only. Callers that act on a request use `resolve`, which also checks the device."""
    return _live().filter(token_hash=hash_token(token)).first()


def find_by_id(pk: UUID) -> StaffSession | None:
    return _live().filter(pk=pk).first()


def ended_because(session: StaffSession) -> str | None:
    now = timezone.now()
    if not session.user.can_sign_in or not session.user.is_staff_member:
        return "account_disabled"
    if session.expires_at <= now:
        return "absolute_timeout"
    idle = timedelta(minutes=get_security().idle_timeout_minutes)
    if session.is_active_stage and now - session.last_seen_at > idle:
        return "idle_timeout"
    return None


def resolve(token: str, request: HttpRequest) -> StaffSession | None:
    session = find(token)
    if session is None:
        return None
    now = timezone.now()
    reason = ended_because(session)
    if reason is None and not hmac.compare_digest(session.fingerprint, fingerprint(request)):
        reason = "fingerprint_mismatch"
    if reason is None:
        if now - session.last_seen_at > timedelta(seconds=30):  # one write per 30s, not per request
            StaffSession.objects.filter(pk=session.pk).update(last_seen_at=now)
        return session
    revoke(session, reason)
    if reason == "fingerprint_mismatch":
        from newsplatform.staff_security.alerts import notify

        auth_event("session_hijack_suspected", ok=False, user=session.user)
        transaction.on_commit(lambda: notify(session.user, "session_hijack_suspected"))
    return None
