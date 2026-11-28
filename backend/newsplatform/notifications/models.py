"""Readers' browsers that asked to be told of new stories (Web Push), and the site's own push key."""

from django.conf import settings
from django.db import models

from newsplatform.common.models import BaseModel


class PushSubscription(BaseModel):
    """One browser. Anyone may subscribe, signed in or not; a push service that says "gone" removes it."""

    endpoint = models.URLField(max_length=1000, unique=True)
    p256dh = models.CharField(max_length=120)
    auth = models.CharField(max_length=40)
    locale = models.CharField(max_length=5, default="sw")
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    failures = models.PositiveSmallIntegerField(default=0)

    class Meta:
        indexes = [models.Index(fields=["locale", "id"])]


class PushKey(BaseModel):
    """The VAPID key pair, made once. The private half is sealed like every other secret (common.crypto)."""

    public = models.CharField(max_length=100)
    private = models.JSONField()


class NoticeKind(models.TextChoices):
    LIVE = "live", "Live"
    BREAKING = "breaking", "Breaking"
    STORY = "story", "Story"
    NOTICE = "notice", "Notice"


class Notice(BaseModel):
    """What the bell lists (ADR-0051): live coverage and breaking news as they are first published, and
    whatever the newsroom chooses to put in front of readers: a story, or a few words of its own.
    One row per language."""

    kind = models.CharField(max_length=10, choices=NoticeKind)
    locale = models.CharField(max_length=5)
    title = models.CharField(max_length=140)
    body = models.CharField(max_length=300, blank=True)
    url = models.CharField(max_length=300, blank=True)  # a path on this site, or nothing
    image = models.CharField(max_length=500, blank=True)
    post = models.ForeignKey(
        "content.Post", null=True, blank=True, on_delete=models.CASCADE, related_name="+"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )

    class Meta:
        indexes = [models.Index(fields=["locale", "-created_at"])]
