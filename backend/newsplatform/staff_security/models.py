from datetime import timedelta

from django.conf import settings
from django.db import models
from django.utils import timezone

from newsplatform.common.models import BaseModel


class SessionStage(models.TextChoices):
    MFA_ENROLL = "mfa_enroll"
    MFA_CHALLENGE = "mfa_challenge"
    ACTIVE = "active"


class StaffSession(BaseModel):
    """Opaque server-side session. Only a hash of the token is stored."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="staff_sessions"
    )
    token_hash = models.CharField(max_length=64, unique=True)
    stage = models.CharField(max_length=16, choices=SessionStage)
    last_seen_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    mfa_verified_at = models.DateTimeField(null=True)
    mfa_method = models.CharField(max_length=16, blank=True, default="")
    mfa_failures = models.PositiveSmallIntegerField(default=0)
    challenge = models.BinaryField(null=True)
    challenge_purpose = models.CharField(max_length=16, blank=True, default="")
    challenge_expires_at = models.DateTimeField(null=True)
    fingerprint = models.CharField(max_length=64)
    device_label = models.CharField(max_length=120)
    ip = models.CharField(max_length=45, blank=True, default="")
    country = models.CharField(max_length=2, blank=True, default="")
    revoked_at = models.DateTimeField(null=True)
    revoke_reason = models.CharField(max_length=40, blank=True, default="")

    def __str__(self) -> str:
        return f"{self.user_id} {self.stage}"

    @property
    def is_active_stage(self) -> bool:
        return self.stage == SessionStage.ACTIVE

    def has_recent_mfa(self) -> bool:
        from newsplatform.site_config.services import get_security

        window = timedelta(minutes=get_security().step_up_minutes)
        return self.mfa_verified_at is not None and timezone.now() - self.mfa_verified_at < window


class Passkey(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="passkeys")
    credential_id = models.BinaryField(unique=True)
    public_key = models.BinaryField()
    sign_count = models.BigIntegerField(default=0)
    transports = models.JSONField(default=list)
    backed_up = models.BooleanField(default=False)
    name = models.CharField(max_length=60)
    last_used_at = models.DateTimeField(null=True)

    def __str__(self) -> str:
        return self.name


class TotpDevice(BaseModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="totp")
    secret = models.JSONField()  # envelope ciphertext
    confirmed_at = models.DateTimeField(null=True)
    last_step = models.BigIntegerField(default=0)  # a code works once

    def __str__(self) -> str:
        return str(self.user_id)


class RecoveryCode(BaseModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="recovery_codes"
    )
    code_hash = models.CharField(max_length=64, unique=True)
    used_at = models.DateTimeField(null=True)

    def __str__(self) -> str:
        return str(self.user_id)


class TokenKind(models.TextChoices):
    INVITE = "invite"
    RESET = "reset"


class StaffToken(BaseModel):
    """Expiring single-use invitation or credential-reset link."""

    kind = models.CharField(max_length=8, choices=TokenKind)
    token_hash = models.CharField(max_length=64, unique=True)
    email = models.EmailField()
    user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.CASCADE, related_name="+")
    grants = models.JSONField(default=list)
    reset_mfa = models.BooleanField(default=False)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True)
    revoked_at = models.DateTimeField(null=True)

    def __str__(self) -> str:
        return f"{self.kind} {self.id}"

    @property
    def is_usable(self) -> bool:
        return not self.used_at and not self.revoked_at and self.expires_at > timezone.now()


class KnownDevice(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="known_devices")
    fingerprint = models.CharField(max_length=64)
    country = models.CharField(max_length=2, blank=True, default="")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "fingerprint", "country"], name="device_unique")
        ]

    def __str__(self) -> str:
        return str(self.user_id)


class AuthEvent(BaseModel):
    """Auth log: success, failure, lockout, anomaly. Written outside business transactions."""

    kind = models.CharField(max_length=40, db_index=True)
    ok = models.BooleanField()
    user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+")
    subject = models.CharField(
        max_length=64, blank=True, default="", db_index=True
    )  # hash of the typed email
    ip = models.CharField(max_length=45, blank=True, default="")
    country = models.CharField(max_length=2, blank=True, default="")
    user_agent = models.CharField(max_length=400, blank=True, default="")
    detail = models.CharField(max_length=200, blank=True, default="")
    request_id = models.CharField(max_length=64, blank=True, default="")

    def __str__(self) -> str:
        return f"{self.kind} {'ok' if self.ok else 'fail'}"
