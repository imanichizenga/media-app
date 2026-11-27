from typing import ClassVar

from django.contrib.auth.base_user import AbstractBaseUser, BaseUserManager
from django.db import models
from django.db.models import Q
from django.db.models.functions import Lower

from newsplatform.common.models import BaseModel


class UserStatus(models.TextChoices):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    BANNED = "banned"
    DEACTIVATED = "deactivated"


class UserManager(BaseUserManager["User"]):
    def create_user(
        self,
        *,
        email: str | None = None,
        phone: str | None = None,
        password: str | None = None,
        **extra: object,
    ) -> User:
        if not email and not phone and not extra.get("username"):
            raise ValueError("A user needs an email, a phone number or a username")
        user = self.model(email=email.strip().lower() if email else None, phone=phone, **extra)
        user.set_password(password)
        user.full_clean(exclude=["password"])
        user.save()
        return user


class User(AbstractBaseUser, BaseModel):
    """One person. Public engagement and staff access are separate realms over this row (ADR-0004)."""

    # NULL, not "": many users have no email, and NULLs do not collide in the unique index.
    email = models.EmailField(null=True, blank=True)  # noqa: DJ001
    phone = models.CharField(max_length=16, null=True, blank=True)  # noqa: DJ001 (E.164)
    display_name = models.CharField(max_length=80, blank=True)  # a new reader says it after signing in
    locale = models.CharField(max_length=5, default="sw")
    status = models.CharField(max_length=16, choices=UserStatus, default=UserStatus.ACTIVE)
    is_staff_member = models.BooleanField(default=False)
    # Readers (ADR-0050): a handle others see, and when they asked to be forgotten (deleted after a grace
    # period).
    username = models.CharField(max_length=30, null=True, blank=True)  # noqa: DJ001
    deletion_requested_at = models.DateTimeField(null=True, blank=True)
    # The reader's own choice: off, their name is left out of the lists of who read a story.
    hide_from_readers = models.BooleanField(default=False)

    USERNAME_FIELD = "id"
    REQUIRED_FIELDS: ClassVar[list[str]] = []
    objects: ClassVar[UserManager] = UserManager()

    class Meta:
        constraints = [
            models.UniqueConstraint(Lower("email"), name="user_email_ci_unique"),
            models.UniqueConstraint(fields=["phone"], name="user_phone_unique"),
            models.UniqueConstraint(Lower("username"), name="user_username_ci_unique"),
            models.CheckConstraint(
                condition=Q(email__isnull=False) | Q(phone__isnull=False) | Q(username__isnull=False),
                name="user_has_identifier",
            ),
            models.CheckConstraint(
                condition=Q(phone__isnull=True) | Q(phone__regex=r"^\+[1-9][0-9]{6,14}$"),
                name="user_phone_e164",
            ),
        ]

    def __str__(self) -> str:
        return str(self.id)

    @property
    def can_sign_in(self) -> bool:
        return self.status == UserStatus.ACTIVE


class IdentityProvider(models.TextChoices):
    PHONE = "phone"
    GOOGLE = "google"
    APPLE = "apple"


class Identity(BaseModel):
    """One way a reader signs in. A reader may link several; each belongs to one reader only."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="identities")
    provider = models.CharField(max_length=10, choices=IdentityProvider)
    subject = models.CharField(max_length=255)  # E.164 for phone, `sub` for Google and Apple
    email = models.EmailField(null=True, blank=True)  # noqa: DJ001
    # Apple's refresh token, kept only to revoke it when the reader deletes the account.
    revoke_token = models.TextField(blank=True, default="")
    last_used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["provider", "subject"], name="identity_unique")]


class RefreshToken(BaseModel):
    """Rotating refresh tokens, one family per sign-in. A used token presented again revokes its whole
    family."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="refresh_tokens")
    family = models.UUIDField(db_index=True)
    token_hash = models.CharField(max_length=64, unique=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    revoked_at = models.DateTimeField(null=True, blank=True)
    device = models.CharField(max_length=120, blank=True, default="")
    ip = models.GenericIPAddressField(null=True, blank=True)


class Consent(BaseModel):
    """What a reader agreed to, and which version (PDPA Tanzania 2022)."""

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="consents")
    kind = models.CharField(max_length=20)  # "terms": community guidelines and privacy policy, in one tick
    version = models.CharField(max_length=20)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "kind", "version"], name="consent_unique")]


class OtpChallenge(BaseModel):
    """One SMS code. Only its hash is kept; it lasts minutes, allows a few tries, and is used once."""

    phone = models.CharField(max_length=16, db_index=True)
    code_hash = models.CharField(max_length=64)
    expires_at = models.DateTimeField()
    attempts = models.PositiveSmallIntegerField(default=0)
    consumed_at = models.DateTimeField(null=True, blank=True)
    ip = models.GenericIPAddressField(null=True, blank=True)
    provider_ref = models.CharField(max_length=64, blank=True, default="")
