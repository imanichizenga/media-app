from django.conf import settings
from django.db import models
from django.db.models import F, Q

from newsplatform.common.models import BaseModel


class ApprovalStatus(models.TextChoices):
    PENDING = "pending"
    EXECUTED = "executed"
    REJECTED = "rejected"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class ApprovalRequest(BaseModel):
    """A change waiting for a second person. `payload` holds identifiers only, never secrets."""

    action = models.CharField(max_length=64)
    summary = models.CharField(max_length=300)
    payload = models.JSONField()
    dedupe_key = models.CharField(max_length=200)
    reason = models.TextField(blank=True, default="")
    status = models.CharField(max_length=16, choices=ApprovalStatus, default=ApprovalStatus.PENDING)
    requested_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    decided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.PROTECT, related_name="+"
    )
    decided_at = models.DateTimeField(null=True)
    decision_note = models.TextField(blank=True, default="")
    expires_at = models.DateTimeField()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["action", "dedupe_key"], condition=Q(status="pending"), name="approval_one_pending"
            ),
            # The database itself refuses self-approval.
            models.CheckConstraint(
                condition=~Q(status="executed") | ~Q(decided_by=F("requested_by")), name="approval_four_eyes"
            ),
        ]

    def __str__(self) -> str:
        return f"{self.action} {self.status}"
