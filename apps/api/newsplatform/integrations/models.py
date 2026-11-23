from django.conf import settings
from django.db import models
from django.db.models import Q

from newsplatform.common.models import BaseModel


class ConfigStatus(models.TextChoices):
    DRAFT = "draft"
    ACTIVE = "active"
    FAILING = "failing"


SUMMARY_STATUSES = [("unconfigured", "unconfigured"), *ConfigStatus.choices]


class RunStatus(models.TextChoices):
    QUEUED = "queued"
    RUNNING = "running"
    PASSED = "passed"
    FAILED = "failed"


class IntegrationConfig(BaseModel):
    provider = models.SlugField(max_length=48)
    environment = models.CharField(max_length=16)
    status = models.CharField(max_length=16, choices=ConfigStatus, default=ConfigStatus.DRAFT)
    active_version = models.ForeignKey(
        "IntegrationVersion", null=True, on_delete=models.PROTECT, related_name="+"
    )
    last_tested_at = models.DateTimeField(null=True)
    last_test_passed = models.BooleanField(null=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["provider", "environment"], name="integration_unique")]

    def __str__(self) -> str:
        return f"{self.provider}@{self.environment}"


class IntegrationVersion(BaseModel):
    """Immutable. A test result therefore always describes exactly what would be activated."""

    config = models.ForeignKey(IntegrationConfig, on_delete=models.CASCADE, related_name="versions")
    number = models.PositiveIntegerField()
    schema_version = models.PositiveSmallIntegerField()
    fields = models.JSONField(default=dict)
    secrets = models.JSONField(null=True)  # envelope ciphertext
    secret_hints = models.JSONField(default=dict)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["config", "number"], name="integration_version_unique")
        ]

    def __str__(self) -> str:
        return f"{self.config_id} v{self.number}"


class IntegrationTestRun(BaseModel):
    version = models.ForeignKey(IntegrationVersion, on_delete=models.CASCADE, related_name="test_runs")
    status = models.CharField(max_length=16, choices=RunStatus, default=RunStatus.QUEUED)
    params = models.JSONField(default=dict)
    steps = models.JSONField(default=list)
    started_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )
    finished_at = models.DateTimeField(null=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["version"], condition=Q(status__in=["queued", "running"]), name="one_test_at_a_time"
            )
        ]

    def __str__(self) -> str:
        return f"{self.version_id} {self.status}"


class IntegrationCall(BaseModel):
    """Log of outbound provider calls. Payloads are redacted before they are stored."""

    provider = models.SlugField(max_length=48, db_index=True)
    operation = models.CharField(max_length=120)
    ok = models.BooleanField()
    status = models.CharField(max_length=40, blank=True, default="")
    latency_ms = models.PositiveIntegerField()
    detail = models.TextField(blank=True, default="")
    request_id = models.CharField(max_length=64, blank=True, default="")

    def __str__(self) -> str:
        return f"{self.provider}.{self.operation}"
