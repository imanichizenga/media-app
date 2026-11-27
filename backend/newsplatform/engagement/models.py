"""Readers' engagement (ADR-0050). Rows are the truth; the counts readers see come from Redis
(counters.py)."""

from django.db import models

from newsplatform.common.models import BaseModel


class Like(BaseModel):
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="likes")
    post = models.ForeignKey("content.Post", on_delete=models.CASCADE, related_name="likes")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "post"], name="like_unique")]
        indexes = [models.Index(fields=["user", "-created_at"], name="like_user_recent")]


class Bookmark(BaseModel):
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="bookmarks")
    post = models.ForeignKey("content.Post", on_delete=models.CASCADE, related_name="bookmarks")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "post"], name="bookmark_unique")]
        indexes = [models.Index(fields=["user", "-created_at"], name="bookmark_user_recent")]


class CommentStatus(models.TextChoices):
    VISIBLE = "visible"
    HELD = "held"  # pre-moderated: waits for a moderator (M5)
    REMOVED = "removed"


class Comment(BaseModel):
    """Threaded one level deep, as readers know from Instagram: a reply to a reply belongs to the first
    comment."""

    post = models.ForeignKey("content.Post", on_delete=models.CASCADE, related_name="comments")
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="comments")
    parent = models.ForeignKey(
        "self", on_delete=models.CASCADE, null=True, blank=True, related_name="replies"
    )
    body = models.TextField(max_length=2000)
    status = models.CharField(max_length=10, choices=CommentStatus, default=CommentStatus.VISIBLE)
    like_count = models.PositiveIntegerField(default=0)
    reply_count = models.PositiveIntegerField(default=0)
    pinned = models.BooleanField(default=False)

    class Meta:
        indexes = [
            models.Index(fields=["post", "status", "parent", "-created_at"], name="comment_thread"),
            models.Index(fields=["parent", "status", "created_at"], name="comment_replies"),
        ]


class CommentLike(BaseModel):
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="comment_likes")
    comment = models.ForeignKey(Comment, on_delete=models.CASCADE, related_name="likes")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "comment"], name="comment_like_unique")]


class FollowKind(models.TextChoices):
    AUTHOR = "author"
    CATEGORY = "category"


class Follow(BaseModel):
    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="follows")
    kind = models.CharField(max_length=10, choices=FollowKind)
    target = models.UUIDField()  # an author's user id or a category id

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "kind", "target"], name="follow_unique")]
        indexes = [models.Index(fields=["kind", "target"], name="follow_target")]


class PostStats(models.Model):
    """Views and readers saved from Redis every few minutes (engagement.views): what outlives the cache."""

    post = models.OneToOneField(
        "content.Post", on_delete=models.CASCADE, primary_key=True, related_name="stats"
    )
    views = models.BigIntegerField(default=0)
    readers = models.BigIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"{self.post_id}: {self.views} views, {self.readers} readers"


class Reading(BaseModel):
    """A signed-in reader opened a story: the list readers see when they tap the readers count."""

    user = models.ForeignKey("accounts.User", on_delete=models.CASCADE, related_name="readings")
    post = models.ForeignKey("content.Post", on_delete=models.CASCADE, related_name="readings")
    last_at = models.DateTimeField()

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "post"], name="reading_unique")]
        indexes = [models.Index(fields=["post", "-last_at"], name="reading_recent")]
