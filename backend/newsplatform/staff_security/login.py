import redis
from django.contrib.auth.hashers import check_password
from django.db import transaction
from django.http import HttpRequest

from newsplatform.accounts.models import User
from newsplatform.common import context
from newsplatform.common.errors import DomainError, Forbidden, RateLimited, ServiceUnavailable
from newsplatform.common.ratelimit import Limit, check, subject_key
from newsplatform.common.redis import cache
from newsplatform.site_config.services import get_security
from newsplatform.staff_security import sessions
from newsplatform.staff_security.alerts import notify
from newsplatform.staff_security.events import auth_event
from newsplatform.staff_security.models import KnownDevice, SessionStage, StaffSession
from newsplatform.staff_security.passwords import DUMMY_HASH


class Lockout:
    """Progressive delay then lockout.

    Keyed on account+IP so an attacker cannot lock a victim out from elsewhere, with a much higher
    account-wide ceiling against distributed guessing. Fails closed when Redis is down.
    """

    def __init__(self, email: str) -> None:
        pair, account = subject_key(email, context.current().ip or "-"), subject_key(email)
        self.keys = [(f"lo:{{{pair}}}", 1), (f"lo:{{{account}}}", 12)]

    def check(self) -> None:
        policy = get_security()
        try:
            for key, factor in self.keys:
                blocked = cache().ttl(f"{key}:block")
                if blocked and blocked > 0:
                    raise RateLimited(retry_after=blocked, detail="Too many attempts. Try again later.")
                if int(cache().get(key) or 0) >= policy.lockout_threshold * factor:
                    raise RateLimited(retry_after=max(1, cache().ttl(key)), detail="Too many attempts.")
        except redis.RedisError as exc:
            raise ServiceUnavailable("Sign-in is temporarily unavailable") from exc

    def fail(self) -> bool:
        policy, locked = get_security(), False
        window = policy.lockout_minutes * 60
        for key, factor in self.keys:
            count = int(cache().incr(key))
            cache().expire(key, window)
            if count >= policy.lockout_threshold * factor:
                cache().set(f"{key}:block", 1, ex=window)
                locked = True
            elif factor == 1 and count >= 3:
                cache().set(f"{key}:block", 1, ex=min(2 ** (count - 2), 60))
        return locked

    def clear(self) -> None:
        pair = self.keys[0][0]
        cache().delete(pair)
        cache().delete(f"{pair}:block")


def has_mfa(user: User) -> bool:
    return (
        user.passkeys.exists() or User.objects.filter(pk=user.pk, totp__confirmed_at__isnull=False).exists()
    )


def password_login(*, email: str, password: str, request: HttpRequest) -> tuple[StaffSession, str]:
    email, ip = email.strip().lower(), context.current().ip or "-"
    check("login-ip", subject_key(ip), Limit(30, 60), fail_closed=True)
    lockout = Lockout(email)
    lockout.check()
    user = User.objects.filter(email__iexact=email).first()
    ok = check_password(password, user.password if user else DUMMY_HASH)
    if not (ok and user and user.can_sign_in and user.is_staff_member):
        locked = lockout.fail()
        auth_event(
            "login_locked" if locked else "login_password", ok=False, user=user, subject=subject_key(email)
        )
        raise DomainError("Email or password is incorrect.", code="invalid_credentials", status=401)
    lockout.clear()
    auth_event("login_password", ok=True, user=user)
    stage = SessionStage.MFA_CHALLENGE if has_mfa(user) else SessionStage.MFA_ENROLL
    return sessions.create(user, stage, request)


def _enforce_geo(session: StaffSession) -> None:
    """Not in a transaction: the block, its log entry and its alert must survive the exception."""
    policy = get_security()
    seen = set(
        KnownDevice.objects.filter(user=session.user).exclude(country="").values_list("country", flat=True)
    )
    if not session.country or not seen or session.country in seen or policy.geo_anomaly_action == "off":
        return
    blocked = policy.geo_anomaly_action == "block"
    auth_event("geo_anomaly", ok=not blocked, user=session.user, detail=session.country)
    notify(session.user, "geo_anomaly", session.country)
    if blocked:
        sessions.revoke(session, "geo_blocked")
        raise _GeoBlocked


def complete(session: StaffSession, method: str) -> str:
    """MFA passed: apply anomaly policy, remember the device, issue the real session."""
    _enforce_geo(session)
    user = session.user
    with transaction.atomic():
        first_login = not KnownDevice.objects.filter(user=user).exists()
        _, new = KnownDevice.objects.get_or_create(
            user=user, fingerprint=session.fingerprint, country=session.country
        )
        if new and not first_login:
            auth_event("new_device", ok=True, user=user, detail=session.device_label)
            transaction.on_commit(lambda: notify(user, "new_device", session.device_label))
        auth_event("login_complete", ok=True, user=user, detail=method)
        return sessions.promote(session, method)


class _GeoBlocked(Forbidden):
    code = "geo_blocked"

    def __init__(self) -> None:
        super().__init__("Sign-in from this country is blocked. Ask an administrator.")
