from django.conf import settings
from django.db import models

from newsplatform.common.models import BaseModel


class SettingsSection(BaseModel):
    key = models.SlugField(max_length=32, unique=True)
    version = models.PositiveIntegerField(default=1)
    data = models.JSONField(default=dict)
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )

    def __str__(self) -> str:
        return f"{self.key} v{self.version}"


class BrandLogo(BaseModel):
    """A cleaned logo and its renditions. Kept here, not in the media bucket: a few small files that must
    exist before storage is configured, served under names that contain their own digest."""

    class Kind(models.TextChoices):
        WORDMARK = "wordmark"
        SYMBOL = "symbol"

    kind = models.CharField(max_length=8, choices=Kind.choices)
    source = models.CharField(max_length=3, choices=[("svg", "svg"), ("png", "png")])
    digest = models.CharField(max_length=32, db_index=True)
    width = models.PositiveIntegerField()
    height = models.PositiveIntegerField()
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )

    class Meta:
        constraints = [models.UniqueConstraint(fields=["kind", "digest"], name="brand_logo_once")]

    def __str__(self) -> str:
        return f"{self.kind} {self.digest}"


class BrandLogoFile(models.Model):
    logo = models.ForeignKey(BrandLogo, on_delete=models.CASCADE, related_name="files")
    name = models.CharField(max_length=24)
    data = models.BinaryField()

    class Meta:
        constraints = [models.UniqueConstraint(fields=["logo", "name"], name="brand_logo_file_once")]

    def __str__(self) -> str:
        return f"{self.logo_id}/{self.name}"


class BrandVersion(BaseModel):
    """Every published brand. Never changed: a stylesheet address must answer the same bytes for ever."""

    number = models.PositiveIntegerField(unique=True)
    data = models.JSONField()
    css_hash = models.CharField(max_length=16, db_index=True)
    css = models.TextField()
    note = models.CharField(max_length=500, blank=True)
    restored_from = models.PositiveIntegerField(null=True)
    published_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )

    def __str__(self) -> str:
        return f"brand {self.number}"
