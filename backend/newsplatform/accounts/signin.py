"""Readers sign in (ADR-0050): a phone and an SMS code, Google, or Apple. The first sign-in makes the account.

SMS codes cost money and attract fraud (SMS pumping), so before one is sent: the country must be allowed, and
the
number, the network, the number range and the whole site each have a limit. Codes are six digits from a
CSPRNG,
kept only as a keyed hash, last minutes, allow a few tries, and are used once.
"""

import hashlib
import hmac
import re
import secrets
import uuid
from dataclasses import dataclass
from datetime import timedelta
from typing import Any

import structlog
from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone

from newsplatform.accounts import phones, tokens
from newsplatform.accounts.models import Consent, Identity, IdentityProvider, OtpChallenge, User, UserStatus
from newsplatform.common.errors import DomainError, RateLimited, ServiceUnavailable
from newsplatform.common.ratelimit import Limit, check, subject_key
from newsplatform.integrations.base import StepFailed
from newsplatform.site_config.schemas import SignIn
from newsplatform.site_config.services import get_section

log = structlog.get_logger(__name__)


def rules() -> SignIn:
    section = get_section("sign_in")[0]
    assert isinstance(section, SignIn)  # noqa: S101 (type narrowing)
    return section


# ---- which ways are open ----
def beem() -> Any:
    from newsplatform.integrations.providers.beem import BeemConfig
    from newsplatform.integrations.services import get_active

    return get_active("beem_sms", BeemConfig)


def google() -> Any:
    from newsplatform.integrations.providers.google_signin import GoogleConfig
    from newsplatform.integrations.services import get_active

    return get_active("google_signin", GoogleConfig)


def apple() -> Any:
    from newsplatform.integrations.providers.apple_signin import AppleConfig
    from newsplatform.integrations.services import get_active

    return get_active("apple_signin", AppleConfig)


def methods() -> dict[str, Any]:
    """What a sign-in sheet offers: a way is shown only when it is switched on and its vendor is
    configured."""
    r = rules()
    g, a = google(), apple()
    return {
        "phone": r.phone and (beem() is not None or settings.LOCAL_SMS),
        "google": bool(r.google and g),
        "google_client_id": g.web_client_id if r.google and g else "",
        "apple": bool(r.apple and a),
        "apple_services_id": a.services_id if r.apple and a else "",
        "countries": r.countries,
        "code_length": 6,
        "resend_seconds": r.resend_seconds,
        "terms_version": r.terms_version,
        "local_sms": settings.LOCAL_SMS,
    }


# ---- SMS codes ----
def _code_hash(challenge: uuid.UUID, code: str) -> str:
    key = hmac.new(settings.SECRET_KEY.encode(), b"reader-otp-v1", hashlib.sha256).digest()
    return hmac.new(key, f"{challenge}:{code}".encode(), hashlib.sha256).hexdigest()


def _text(code: str, locale: str, r: SignIn) -> str:
    from newsplatform.site_config.services import get_brand

    brand = get_brand()[0].identity.brand_name
    words = (
        f"{code} is your {brand} sign-in code. It lasts {r.code_minutes} minutes. Do not share it."
        if locale == "en"
        else f"{code} ni msimbo wako wa kuingia {brand}. Unadumu dakika {r.code_minutes}. Usimpe mtu."
    )
    # Android's SMS Retriever reads the code from a message that ends with the app's hash.
    return f"{words}\n\n{r.android_app_hash}" if r.android_app_hash else words


@dataclass(frozen=True, slots=True)
class Sent:
    challenge: uuid.UUID
    phone: str
    resend_in: int
    expires_in: int
    local_code: str | None = None


def request_code(raw_phone: str, *, ip: str, locale: str = "sw") -> Sent:
    r = rules()
    if not r.phone:
        raise DomainError("Signing in by phone is switched off.", code="method_disabled")
    phone = phones.normalise(raw_phone)
    if phone is None:
        raise DomainError("Write the number with its country code, e.g. 0712 345 678.", code="invalid_phone")
    country = phones.country_of(phone, r.countries)
    if country is None:
        raise DomainError("Codes cannot be sent to this country.", code="country_not_allowed")
    config = beem()
    if config is None and not settings.LOCAL_SMS:
        raise ServiceUnavailable("SMS is not configured yet.", code="sms_not_configured")
    # The limits, cheapest first. Failing closed: if Redis cannot count, no SMS is sent.
    check("otp-resend", subject_key(phone), Limit(1, r.resend_seconds), fail_closed=True)
    check("otp-phone", subject_key(phone), Limit(r.per_phone_daily, 86400), fail_closed=True)
    check("otp-ip", subject_key(ip), Limit(r.per_ip_hourly, 3600), fail_closed=True)
    prefix = phone[: len(country) + 1 + 3]  # the operator and the first digits of the range
    check("otp-prefix", subject_key(prefix), Limit(r.per_prefix_hourly, 3600), fail_closed=True)
    try:
        check("otp-budget", "all", Limit(r.sms_hourly_budget, 3600), fail_closed=True)
    except RateLimited:
        log.error("sms_hourly_budget_reached", budget=r.sms_hourly_budget)
        raise

    code = f"{secrets.randbelow(1_000_000):06d}"
    challenge = OtpChallenge(
        phone=phone, expires_at=timezone.now() + timedelta(minutes=r.code_minutes), ip=ip
    )
    challenge.code_hash = _code_hash(challenge.id, code)
    if config is not None:
        from newsplatform.integrations.providers import beem as provider

        try:
            challenge.provider_ref = provider.send(config, to=phone, text=_text(code, locale, r))[:64]
        except StepFailed as exc:
            log.warning("otp_sms_failed", detail=exc.detail)
            raise ServiceUnavailable(
                "The SMS could not be sent. Try again shortly.", code="sms_failed"
            ) from exc
        local = None
    else:
        log.info("otp_local", phone=phones.masked(phone), code=code)
        local = code
    challenge.save()
    log.info("otp_sent", phone=phones.masked(phone), country=country)
    return Sent(challenge.id, phone, r.resend_seconds, r.code_minutes * 60, local)


def check_code(challenge_id: str, code: str) -> str:
    """The phone the code proves, or DomainError. Each wrong try counts; the right one is used up."""
    r = rules()
    code = re.sub(r"\D", "", code or "")
    # The try is counted in its own transaction, so a wrong code's count is kept when the error is raised
    # after.
    with transaction.atomic():
        try:
            row = OtpChallenge.objects.select_for_update().filter(pk=challenge_id).first()
        except ValueError, DomainError:
            row = None
        now = timezone.now()
        if row is None or row.consumed_at or row.expires_at <= now:
            failure: DomainError | None = DomainError(
                "This code has expired. Ask for a new one.", code="code_expired"
            )
        elif row.attempts >= r.attempts:
            failure = DomainError("Too many wrong tries. Ask for a new code.", code="code_locked")
        else:
            row.attempts += 1
            if hmac.compare_digest(row.code_hash, _code_hash(row.id, code)):
                row.consumed_at, failure = now, None
            else:
                left = r.attempts - row.attempts
                failure = DomainError("That code is not right.", code="code_wrong", attempts_left=left)
            row.save(update_fields=["attempts", "consumed_at", "updated_at"])
    if failure is not None or row is None:
        raise failure or DomainError("This code has expired.", code="code_expired")
    return row.phone


# ---- accounts ----
@dataclass(frozen=True, slots=True)
class SignedIn:
    user: User
    pair: tokens.Pair
    created: bool


def _username(seed: str) -> str:
    base = re.sub(r"[^a-z0-9]", "", seed.lower())[:16] or "msomaji"
    for _ in range(20):
        candidate = f"{base}{secrets.randbelow(10_000):04d}"
        if not User.objects.filter(username__iexact=candidate).exists():
            return candidate
    return f"msomaji{uuid.uuid4().hex[:10]}"


def _account(
    provider: str, subject: str, *, email: str | None, name: str, phone: str | None, revoke_token: str = ""
) -> tuple[User, bool]:
    """The reader behind this identity; a new one on first sign-in. An email is linked only when verified."""
    with transaction.atomic():
        identity = Identity.objects.select_related("user").filter(provider=provider, subject=subject).first()
        if identity:
            identity.last_used_at = timezone.now()
            if revoke_token:
                identity.revoke_token = revoke_token
            identity.save(update_fields=["last_used_at", "revoke_token", "updated_at"])
            return identity.user, False
        user = None
        if phone:
            user = User.objects.filter(phone=phone).first()
        elif email:
            user = User.objects.filter(email__iexact=email).first()
        created = user is None
        if user is None:
            try:
                with transaction.atomic():
                    user = User.objects.create_user(
                        email=email if not phone else None,
                        phone=phone,
                        display_name=name[:80],
                        username=_username(name or (email or "").split("@")[0]),
                    )
            except IntegrityError as exc:
                raise DomainError("This account already exists. Try again.", code="conflict") from exc
        Identity.objects.create(
            user=user,
            provider=provider,
            subject=subject,
            email=email,
            revoke_token=revoke_token,
            last_used_at=timezone.now(),
        )
        return user, created


def _finish(user: User, created: bool, *, device: str, ip: str | None) -> SignedIn:
    if user.status != UserStatus.ACTIVE:
        if user.status == UserStatus.DEACTIVATED and user.deletion_requested_at:
            # Signing in again within the grace period keeps the account.
            user.status, user.deletion_requested_at = UserStatus.ACTIVE, None
            user.save(update_fields=["status", "deletion_requested_at", "updated_at"])
        else:
            raise DomainError("This account cannot sign in.", code="account_blocked", status=403)
    user.last_login = timezone.now()
    user.save(update_fields=["last_login", "updated_at"])
    log.info("reader_signed_in", user=str(user.pk), created=created)
    return SignedIn(user, tokens.issue(user, device=device, ip=ip), created)


def with_phone(challenge_id: str, code: str, *, device: str = "", ip: str | None = None) -> SignedIn:
    phone = check_code(challenge_id, code)
    user, created = _account(IdentityProvider.PHONE, phone, email=None, name="", phone=phone)
    return _finish(user, created, device=device, ip=ip)


def with_google(
    *,
    id_token: str = "",
    code: str = "",
    redirect_uri: str = "",
    verifier: str = "",
    nonce: str | None = None,
    device: str = "",
    ip: str | None = None,
) -> SignedIn:
    from newsplatform.accounts import oidc
    from newsplatform.integrations.providers import google_signin

    config = google()
    if config is None or not rules().google:
        raise DomainError("Signing in with Google is not available.", code="method_disabled")
    if code:
        try:
            id_token = str(
                google_signin.exchange(config, code=code, redirect_uri=redirect_uri, verifier=verifier)[
                    "id_token"
                ]
            )
        except (StepFailed, KeyError) as exc:
            raise DomainError(
                "Google did not confirm the sign-in. Try again.", code="provider_refused"
            ) from exc
    found = google_signin.discovery()
    who = oidc.verify(
        "google_signin",
        id_token,
        jwks_url=str(found["jwks_uri"]),
        issuers=google_signin.ISSUERS,
        audiences=config.audiences(),
        nonce=nonce,
    )
    email = who.email if who.email_verified else None
    user, created = _account(IdentityProvider.GOOGLE, who.subject, email=email, name=who.name, phone=None)
    return _finish(user, created, device=device, ip=ip)


def with_apple(
    *,
    id_token: str = "",
    code: str = "",
    redirect_uri: str = "",
    name: str = "",
    nonce: str | None = None,
    device: str = "",
    ip: str | None = None,
) -> SignedIn:
    from newsplatform.accounts import oidc
    from newsplatform.integrations.providers import apple_signin

    config = apple()
    if config is None or not rules().apple:
        raise DomainError("Signing in with Apple is not available.", code="method_disabled")
    refresh = ""
    if code:
        try:
            answer = apple_signin.exchange(config, code=code, redirect_uri=redirect_uri)
        except StepFailed as exc:
            raise DomainError(
                "Apple did not confirm the sign-in. Try again.", code="provider_refused"
            ) from exc
        id_token, refresh = str(answer.get("id_token", "")), str(answer.get("refresh_token", ""))
    who = oidc.verify(
        "apple_signin",
        id_token,
        jwks_url=apple_signin.KEYS,
        issuers=[apple_signin.ISSUER],
        audiences=config.audiences(),
        nonce=nonce,
    )
    # Apple sends the name once, on the first authorization, outside the token.
    email = who.email if who.email_verified else None
    user, created = _account(
        IdentityProvider.APPLE, who.subject, email=email, name=name.strip(), phone=None, revoke_token=refresh
    )
    return _finish(user, created, device=device, ip=ip)


# ---- the account itself ----
def needs_onboarding(user: User) -> bool:
    return (
        not user.display_name
        or not Consent.objects.filter(user=user, kind="terms", version=rules().terms_version).exists()
    )


def update_profile(user: User, data: dict[str, Any]) -> User:
    fields = []
    if "display_name" in data:
        name = " ".join(str(data["display_name"]).split())[:80]
        if len(name) < 2:
            raise DomainError("Write your name.", code="validation_error", field="display_name")
        user.display_name = name
        fields.append("display_name")
    if "username" in data:
        handle = str(data["username"]).strip().lstrip("@").lower()
        if not re.fullmatch(r"[a-z0-9_]{3,30}", handle):
            raise DomainError("3 to 30 letters, digits or _.", code="validation_error", field="username")
        if User.objects.filter(username__iexact=handle).exclude(pk=user.pk).exists():
            raise DomainError("This name is taken.", code="username_taken", field="username")
        user.username = handle
        fields.append("username")
    if "locale" in data and data["locale"] in {"sw", "en"}:
        user.locale = data["locale"]
        fields.append("locale")
    if "hide_from_readers" in data:
        user.hide_from_readers = bool(data["hide_from_readers"])
        fields.append("hide_from_readers")
    if data.get("accept_terms"):
        Consent.objects.get_or_create(user=user, kind="terms", version=rules().terms_version)
    if fields:
        user.save(update_fields=[*fields, "updated_at"])
    return user


GRACE_DAYS = 30


def request_deletion(user: User) -> None:
    """Signed out everywhere at once; erased after the grace period unless the reader signs in again."""
    user.status, user.deletion_requested_at = UserStatus.DEACTIVATED, timezone.now()
    user.save(update_fields=["status", "deletion_requested_at", "updated_at"])
    tokens.revoke_all(user)
    log.info("reader_deletion_requested", user=str(user.pk))


def erase_due() -> int:
    """Daily: accounts past their grace period. Apple's tokens are revoked as its guidelines ask."""
    from newsplatform.integrations.providers import apple_signin

    due = User.objects.filter(
        status=UserStatus.DEACTIVATED,
        deletion_requested_at__lte=timezone.now() - timedelta(days=GRACE_DAYS),
        is_staff_member=False,
    )
    count = 0
    config = apple()
    for user in due:
        for identity in user.identities.filter(provider=IdentityProvider.APPLE).exclude(revoke_token=""):
            if config is not None:
                try:
                    apple_signin.revoke(config, token=identity.revoke_token, client_id=config.services_id)
                except Exception:  # an unrevoked Apple token must not keep an account alive
                    log.exception("apple_revoke_failed", user=str(user.pk))
        user.delete()
        count += 1
    return count
