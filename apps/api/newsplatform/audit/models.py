import uuid

from django.db import models


class AuditEntry(models.Model):
    """Append-only, hash-chained. UPDATE, DELETE and TRUNCATE are rejected by database triggers.

    Actor fields are copied, not foreign keys: the record must survive account deletion unchanged.
    """

    seq = models.BigIntegerField(primary_key=True)
    id = models.UUIDField(default=uuid.uuid7, unique=True, editable=False)
    occurred_at = models.DateTimeField(db_index=True)
    actor_id = models.CharField(max_length=36, blank=True, default="", db_index=True)
    actor_label = models.CharField(max_length=120)
    approved_by_id = models.CharField(max_length=36, blank=True, default="")
    action = models.CharField(max_length=80, db_index=True)
    target_type = models.CharField(max_length=80, blank=True, default="")
    target_id = models.CharField(max_length=64, blank=True, default="")
    target_label = models.CharField(max_length=200, blank=True, default="")
    before = models.JSONField(null=True)
    after = models.JSONField(null=True)
    reason = models.TextField(blank=True, default="")
    ip = models.CharField(max_length=45, blank=True, default="")
    user_agent = models.CharField(max_length=400, blank=True, default="")
    request_id = models.CharField(max_length=64, blank=True, default="")
    prev_hash = models.CharField(max_length=64)
    hash = models.CharField(max_length=64, unique=True)

    class Meta:
        indexes = [models.Index(fields=["target_type", "target_id"])]

    def __str__(self) -> str:
        return f"#{self.seq} {self.action}"


class ChainHead(models.Model):
    """Single row, locked while appending so the chain is strictly serial."""

    id = models.SmallIntegerField(primary_key=True, default=1)
    seq = models.BigIntegerField(default=0)
    hash = models.CharField(max_length=64)

    class Meta:
        constraints = [models.CheckConstraint(condition=models.Q(id=1), name="chainhead_singleton")]

    def __str__(self) -> str:
        return f"head@{self.seq}"


class ChainAnchor(models.Model):
    """A chain head copied to WORM storage. If the live chain disagrees, history was rewritten."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid7, editable=False)
    seq = models.BigIntegerField()
    hash = models.CharField(max_length=64)
    bucket = models.CharField(max_length=80)
    key = models.CharField(max_length=300)
    version_id = models.CharField(max_length=200, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"anchor@{self.seq}"
