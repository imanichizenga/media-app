from django.conf import settings
from django.db import models
from django.db.models import Q

from newsplatform.common.models import BaseModel


class PageKey(models.TextChoices):
    """Each has its own address, the same in both languages (seo.paths reserves them)."""

    ABOUT = "about"
    EDITORIAL = "editorial-policy"
    CORRECTIONS = "corrections"
    CONTACT = "contact"
    PRIVACY = "privacy"
    TERMS = "terms"


class Page(BaseModel):
    """The publisher's own words about itself: legal and editorial pages. Content, never code (ADR-0045)."""

    key = models.CharField(max_length=20, choices=PageKey, unique=True)
    version = models.PositiveIntegerField(default=0)  # optimistic concurrency
    published = models.ForeignKey("PageRevision", null=True, on_delete=models.PROTECT, related_name="+")
    first_published_at = models.DateTimeField(null=True)
    published_at = models.DateTimeField(null=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=Q(published__isnull=True) | Q(published_at__isnull=False),
                name="page_published_has_time",
            )
        ]

    def __str__(self) -> str:
        return self.key


class PageRevision(BaseModel):
    """Never changed. What was promised to readers, and when, must be provable."""

    page = models.ForeignKey(Page, on_delete=models.PROTECT, related_name="revisions")
    number = models.PositiveIntegerField()
    texts = models.JSONField()  # {locale: {title, summary, body}}
    note = models.CharField(max_length=300, blank=True, default="")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["page", "number"], name="page_revision_unique")]
        ordering = ["-number"]

    def __str__(self) -> str:
        return f"{self.page_id} r{self.number}"
