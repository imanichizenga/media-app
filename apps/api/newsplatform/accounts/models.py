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
        if not email and not phone:
            raise ValueError("A user needs an email or a phone number")
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
    display_name = models.CharField(max_length=80)
    locale = models.CharField(max_length=5, default="sw")
    status = models.CharField(max_length=16, choices=UserStatus, default=UserStatus.ACTIVE)
    is_staff_member = models.BooleanField(default=False)

    USERNAME_FIELD = "id"
    REQUIRED_FIELDS: ClassVar[list[str]] = []
    objects: ClassVar[UserManager] = UserManager()

    class Meta:
        constraints = [
            models.UniqueConstraint(Lower("email"), name="user_email_ci_unique"),
            models.UniqueConstraint(fields=["phone"], name="user_phone_unique"),
            models.CheckConstraint(
                condition=Q(email__isnull=False) | Q(phone__isnull=False), name="user_has_identifier"
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
