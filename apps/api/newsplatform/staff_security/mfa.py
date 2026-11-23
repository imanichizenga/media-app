import base64
import hashlib
import hmac
import io
import secrets
import time
from datetime import timedelta
from typing import Any

import pyotp
import segno
from django.conf import settings
from django.db import transaction
from django.utils import timezone
from webauthn import (
    generate_authentication_options,
    generate_registration_options,
    verify_authentication_response,
    verify_registration_response,
)
from webauthn.helpers import options_to_json_dict
from webauthn.helpers.exceptions import WebAuthnException
from webauthn.helpers.structs import (
    AuthenticatorSelectionCriteria,
    PublicKeyCredentialDescriptor,
    ResidentKeyRequirement,
    UserVerificationRequirement,
)

from newsplatform.accounts.models import User
from newsplatform.audit.services import record
from newsplatform.common.crypto import decrypt, encrypt
from newsplatform.common.errors import Conflict, DomainError, RateLimited
from newsplatform.common.ratelimit import Limit, check
from newsplatform.site_config.services import brand_name
from newsplatform.staff_security import sessions
from newsplatform.staff_security.alerts import notify
from newsplatform.staff_security.events import auth_event
from newsplatform.staff_security.models import Passkey, RecoveryCode, StaffSession, TotpDevice

_MAX_FAILURES = 5
_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"


class MfaFailed(DomainError):
    code = "mfa_failed"
    status = 401


def _guard(session: StaffSession) -> None:
    # Per user as well as per session: a stolen password must not buy unlimited sessions to guess from.
    check("mfa-user", str(session.user_id), Limit(15, 900), fail_closed=True)


def _fail(session: StaffSession, method: str) -> Exception:
    session.mfa_failures += 1
    StaffSession.objects.filter(pk=session.pk).update(mfa_failures=session.mfa_failures)
    auth_event(f"mfa_{method}", ok=False, user=session.user)
    if session.mfa_failures >= _MAX_FAILURES:
        sessions.revoke(session, "mfa_failures")
        return RateLimited(retry_after=60, detail="Too many attempts. Sign in again.")
    return MfaFailed("That did not match. Try again.")


def methods(user: User) -> list[str]:
    out = ["passkey"] if user.passkeys.exists() else []
    if TotpDevice.objects.filter(user=user, confirmed_at__isnull=False).exists():
        out.append("totp")
    if out and user.recovery_codes.filter(used_at__isnull=True).exists():
        out.append("recovery")
    return out


# ---- challenges -----------------------------------------------------------------------------------------
def _store_challenge(session: StaffSession, challenge: bytes, purpose: str) -> None:
    StaffSession.objects.filter(pk=session.pk).update(
        challenge=challenge,
        challenge_purpose=purpose,
        challenge_expires_at=timezone.now() + timedelta(minutes=3),
    )


def _take_challenge(session: StaffSession, purpose: str) -> bytes:
    """Consumed on first use, valid or not, so a response can never be replayed."""
    with transaction.atomic():
        row = StaffSession.objects.select_for_update().get(pk=session.pk)
        challenge, kind, expiry = row.challenge, row.challenge_purpose, row.challenge_expires_at
        row.challenge, row.challenge_purpose, row.challenge_expires_at = None, "", None
        row.save(update_fields=["challenge", "challenge_purpose", "challenge_expires_at"])
    if not challenge or kind != purpose or not expiry or expiry < timezone.now():
        raise Conflict("The request expired. Try again.", code="challenge_expired")
    return bytes(challenge)


# ---- passkeys -------------------------------------------------------------------------------------------
def _descriptors(user: User) -> list[PublicKeyCredentialDescriptor]:
    return [PublicKeyCredentialDescriptor(id=bytes(p.credential_id)) for p in user.passkeys.all()]


def passkey_register_options(session: StaffSession) -> dict[str, Any]:
    user = session.user
    options = generate_registration_options(
        rp_id=settings.WEBAUTHN_RP_ID,
        rp_name=f"{brand_name()} Admin",
        user_id=user.id.bytes,
        user_name=user.email or "",
        user_display_name=user.display_name,
        exclude_credentials=_descriptors(user),
        authenticator_selection=AuthenticatorSelectionCriteria(
            resident_key=ResidentKeyRequirement.PREFERRED,
            user_verification=UserVerificationRequirement.REQUIRED,
        ),
    )
    _store_challenge(session, options.challenge, "register")
    return options_to_json_dict(options)


@transaction.atomic
def _save_passkey(session: StaffSession, verified: Any, credential: dict[str, Any], name: str) -> list[str]:
    if Passkey.objects.filter(credential_id=verified.credential_id).exists():
        raise Conflict("This passkey is already registered.", code="passkey_exists")
    transports = [str(t)[:20] for t in credential.get("response", {}).get("transports", [])][:8]
    key = Passkey.objects.create(
        user=session.user,
        credential_id=verified.credential_id,
        public_key=verified.credential_public_key,
        sign_count=verified.sign_count,
        transports=transports,
        backed_up=verified.credential_backed_up,
        name=name[:60] or "Passkey",
    )
    record(actor=session.user, action="mfa.passkey_added", target=key, label=key.name)
    return _after_enrol(session.user, "passkey")


def passkey_register(session: StaffSession, credential: dict[str, Any], name: str) -> list[str]:
    challenge = _take_challenge(session, "register")
    try:
        verified = verify_registration_response(
            credential=credential,
            expected_challenge=challenge,
            expected_rp_id=settings.WEBAUTHN_RP_ID,
            expected_origin=settings.ADMIN_ORIGIN,
            require_user_verification=True,
        )
    except (WebAuthnException, ValueError, KeyError) as exc:
        raise MfaFailed("The passkey could not be verified.") from exc
    return _save_passkey(session, verified, credential, name)


def passkey_auth_options(session: StaffSession) -> dict[str, Any]:
    options = generate_authentication_options(
        rp_id=settings.WEBAUTHN_RP_ID,
        allow_credentials=_descriptors(session.user),
        user_verification=UserVerificationRequirement.REQUIRED,
    )
    _store_challenge(session, options.challenge, "authenticate")
    return options_to_json_dict(options)


def passkey_verify(session: StaffSession, credential: dict[str, Any]) -> None:
    _guard(session)
    challenge = _take_challenge(session, "authenticate")
    try:
        raw = base64.urlsafe_b64decode(str(credential["rawId"]) + "==")
        # Scoped to this user: another account's passkey never satisfies this session.
        key = session.user.passkeys.get(credential_id=raw)
        verified = verify_authentication_response(
            credential=credential,
            expected_challenge=challenge,
            expected_rp_id=settings.WEBAUTHN_RP_ID,
            expected_origin=settings.ADMIN_ORIGIN,
            credential_public_key=bytes(key.public_key),
            credential_current_sign_count=key.sign_count,
            require_user_verification=True,
        )
    except (WebAuthnException, Passkey.DoesNotExist, ValueError, KeyError) as exc:
        raise _fail(session, "passkey") from exc
    Passkey.objects.filter(pk=key.pk).update(sign_count=verified.new_sign_count, last_used_at=timezone.now())


# ---- TOTP -----------------------------------------------------------------------------------------------
def _totp_ctx(user: User) -> dict[str, str]:
    return {"purpose": "totp", "user": str(user.pk)}


def totp_begin(session: StaffSession) -> dict[str, str]:
    user, secret = session.user, pyotp.random_base32(32)
    if TotpDevice.objects.filter(user=user, confirmed_at__isnull=False).exists():
        raise Conflict("Remove the current authenticator app first.", code="totp_exists")
    TotpDevice.objects.update_or_create(
        user=user,
        defaults={"secret": encrypt(secret.encode(), _totp_ctx(user)), "confirmed_at": None, "last_step": 0},
    )
    uri = pyotp.TOTP(secret).provisioning_uri(name=user.email or "", issuer_name=f"{brand_name()} Admin")
    buf = io.BytesIO()
    segno.make(uri, error="m").save(buf, kind="svg", scale=5, border=2, xmldecl=False, svgns=True)
    return {"secret": secret, "qr_svg": base64.b64encode(buf.getvalue()).decode()}


def _match_step(device: TotpDevice, code: str) -> int | None:
    totp, now = pyotp.TOTP(decrypt(device.secret, _totp_ctx(device.user)).decode()), int(time.time()) // 30
    for step in (now, now - 1, now + 1):
        if step > device.last_step and hmac.compare_digest(totp.generate_otp(step), code):
            return step
    return None


def _consume_totp(user: User, code: str, *, confirmed: bool) -> bool:
    with transaction.atomic():
        device = (
            TotpDevice.objects.select_for_update(of=("self",))
            .select_related("user")
            .filter(user=user, confirmed_at__isnull=not confirmed)
            .first()
        )
        step = _match_step(device, code) if device else None
        if device is None or step is None:
            return False
        device.last_step = step
        device.confirmed_at = device.confirmed_at or timezone.now()
        device.save()
        return True


def totp_confirm(session: StaffSession, code: str) -> list[str]:
    _guard(session)
    if not _consume_totp(session.user, code, confirmed=False):
        raise _fail(session, "totp_confirm")
    with transaction.atomic():
        record(
            actor=session.user, action="mfa.totp_added", target=session.user, label=session.user.display_name
        )
        return _after_enrol(session.user, "totp")


def totp_verify(session: StaffSession, code: str) -> None:
    _guard(session)
    if not _consume_totp(session.user, code, confirmed=True):
        raise _fail(session, "totp")


# ---- recovery codes -------------------------------------------------------------------------------------
def _hash_code(code: str) -> str:
    clean = "".join(c for c in code.upper() if c.isalnum())
    return hmac.new(settings.SECRET_KEY.encode(), b"recovery:" + clean.encode(), hashlib.sha256).hexdigest()


@transaction.atomic
def generate_recovery_codes(user: User) -> list[str]:
    user.recovery_codes.all().delete()
    raw = ["".join(secrets.choice(_ALPHABET) for _ in range(12)) for _ in range(10)]
    codes = [f"{c[:4]}-{c[4:8]}-{c[8:]}" for c in raw]
    RecoveryCode.objects.bulk_create(RecoveryCode(user=user, code_hash=_hash_code(c)) for c in codes)
    record(actor=user, action="mfa.recovery_generated", target=user, label=user.display_name)
    return codes


def recovery_verify(session: StaffSession, code: str) -> None:
    _guard(session)
    used = session.user.recovery_codes.filter(code_hash=_hash_code(code), used_at__isnull=True).update(
        used_at=timezone.now()
    )  # one statement, so a code cannot be spent twice concurrently
    if not used:
        raise _fail(session, "recovery")
    auth_event("mfa_recovery", ok=True, user=session.user)
    notify(session.user, "credentials_changed", "recovery code used / msimbo wa dharura umetumika")


def _after_enrol(user: User, method: str) -> list[str]:
    """The first factor comes with recovery codes; later ones only send an alert."""
    if not user.recovery_codes.exists():
        return generate_recovery_codes(user)
    transaction.on_commit(lambda: notify(user, "credentials_changed", f"{method} added"))
    return []


@transaction.atomic
def remove_factor(session: StaffSession, *, passkey_id: str | None = None) -> None:
    user = User.objects.select_for_update().get(pk=session.user_id)
    has_totp = TotpDevice.objects.filter(user=user, confirmed_at__isnull=False).exists()
    if user.passkeys.count() + int(has_totp) <= 1:
        raise Conflict("Add another method before removing your last one.", code="last_factor")
    if passkey_id:
        key = user.passkeys.filter(pk=passkey_id).first()
        if key is None:
            raise DomainError("Not found", code="not_found", status=404)
        record(actor=user, action="mfa.passkey_removed", target=key, label=key.name)
        key.delete()
    else:
        record(actor=user, action="mfa.totp_removed", target=user, label=user.display_name)
        TotpDevice.objects.filter(user=user).delete()
    transaction.on_commit(lambda: notify(user, "credentials_changed", "MFA method removed"))
