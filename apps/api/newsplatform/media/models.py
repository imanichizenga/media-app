from django.conf import settings
from django.db import models
from django.db.models import Q

from newsplatform.common.models import BaseModel


class Kind(models.TextChoices):
    IMAGE = "image"
    VIDEO = "video"


class AssetStatus(models.TextChoices):
    UPLOADING = "uploading"
    SCANNING = "scanning"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"
    REJECTED = "rejected"  # malware, or not what it claims to be: never processed, never retried


class Asset(BaseModel):
    kind = models.CharField(max_length=8, choices=Kind)
    status = models.CharField(max_length=12, choices=AssetStatus, default=AssetStatus.UPLOADING)
    filename = models.CharField(max_length=200)
    # Random, so a key reveals nothing and cannot be guessed from an article.
    original_key = models.CharField(max_length=200, unique=True)
    upload_id = models.CharField(max_length=400, blank=True, default="")
    part_size = models.PositiveIntegerField(default=0)
    bytes = models.BigIntegerField()
    mime = models.CharField(max_length=80, blank=True, default="")
    sha256 = models.CharField(max_length=64, blank=True, default="", db_index=True)
    width = models.PositiveIntegerField(null=True)
    height = models.PositiveIntegerField(null=True)
    duration_ms = models.PositiveBigIntegerField(null=True)
    alt_sw = models.CharField(max_length=500, blank=True, default="")
    alt_en = models.CharField(max_length=500, blank=True, default="")
    credit = models.CharField(max_length=200, blank=True, default="")
    license = models.CharField(max_length=200, blank=True, default="")
    # Thousandths of width and height: what must stay visible in any crop.
    focal_x = models.PositiveSmallIntegerField(default=500)
    focal_y = models.PositiveSmallIntegerField(default=500)
    blurhash = models.CharField(max_length=60, blank=True, default="")
    dominant_color = models.CharField(max_length=7, blank=True, default="")
    # Images: {"variants": {"avif": {"640": key}}}. Video: hls, poster, sprite and sprite_vtt keys.
    outputs = models.JSONField(default=dict)
    job_id = models.CharField(max_length=120, blank=True, default="", db_index=True)
    attempts = models.PositiveSmallIntegerField(default=0)
    error_code = models.CharField(max_length=60, blank=True, default="")
    error_detail = models.CharField(max_length=500, blank=True, default="")
    uploaded_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )
    deleted_at = models.DateTimeField(null=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=Q(focal_x__lte=1000) & Q(focal_y__lte=1000), name="asset_focal_point"
            ),
            models.CheckConstraint(condition=Q(bytes__gt=0), name="asset_has_bytes"),
        ]
        indexes = [models.Index(fields=["status", "updated_at"])]

    def __str__(self) -> str:
        return f"{self.kind} {self.pk}"
