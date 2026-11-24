from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.db import models
from django.db.models import Q

from newsplatform.common.models import BaseModel


class Role(BaseModel):
    key = models.SlugField(max_length=48, unique=True)
    name_en = models.CharField(max_length=80)
    name_sw = models.CharField(max_length=80)
    description = models.CharField(max_length=300, blank=True, default="")
    permissions = ArrayField(models.CharField(max_length=64), default=list)
    is_system = models.BooleanField(default=False)
    is_staff = models.BooleanField(default=True)
    is_privileged = models.BooleanField(default=False)

    def __str__(self) -> str:
        return self.key


class RoleAssignment(BaseModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="assignments")
    role = models.ForeignKey(Role, on_delete=models.PROTECT, related_name="assignments")
    scope_type = models.CharField(max_length=32, blank=True, default="")  # "" = global
    scope_id = models.CharField(max_length=64, blank=True, default="")
    granted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "role", "scope_type", "scope_id"], name="assignment_unique"
            ),
            models.CheckConstraint(
                condition=(Q(scope_type="") & Q(scope_id="")) | (~Q(scope_type="") & ~Q(scope_id="")),
                name="assignment_scope_complete",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.user_id}:{self.role_id}"
