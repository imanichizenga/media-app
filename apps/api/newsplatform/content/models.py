from django.conf import settings
from django.contrib.postgres.fields import ArrayField
from django.db import models
from django.db.models import F, Q

from newsplatform.common.locales import Locale
from newsplatform.common.models import BaseModel


class PostType(models.TextChoices):
    ARTICLE = "article"
    BREAKING = "breaking"
    VIDEO = "video"
    GALLERY = "gallery"
    LIVE_BLOG = "live_blog"
    LIVE_STREAM = "live_stream"
    OPINION = "opinion"
    SHORT = "short"
    YOUTUBE = "youtube"
    INSTAGRAM = "instagram_import"


class Status(models.TextChoices):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    IN_REVIEW = "in_review"
    APPROVED = "approved"
    SCHEDULED = "scheduled"
    PUBLISHED = "published"
    UNPUBLISHED = "unpublished"
    ARCHIVED = "archived"


class Post(BaseModel):
    """The working copy. Readers never see this table: they see Publication (ADR-0023)."""

    type = models.CharField(max_length=20, choices=PostType)
    status = models.CharField(max_length=12, choices=Status, default=Status.DRAFT)
    version = models.PositiveIntegerField(default=1)  # optimistic concurrency
    category = models.ForeignKey("taxonomy.Category", on_delete=models.PROTECT, related_name="posts")
    secondary_categories = models.ManyToManyField("taxonomy.Category", related_name="secondary_posts")
    tags = models.ManyToManyField("taxonomy.Tag", related_name="posts")
    regions = models.ManyToManyField("taxonomy.Region", related_name="posts")
    story = models.ForeignKey("taxonomy.Story", null=True, on_delete=models.SET_NULL, related_name="posts")
    hero = models.ForeignKey("media.Asset", null=True, on_delete=models.PROTECT, related_name="hero_of")
    video = models.ForeignKey("media.Asset", null=True, on_delete=models.PROTECT, related_name="video_of")
    youtube_id = models.CharField(max_length=11, blank=True, default="")
    source_url = models.URLField(max_length=500, blank=True, default="")
    is_evergreen = models.BooleanField(default=False)
    is_sensitive = models.BooleanField(default=False)
    content_warning = models.CharField(max_length=200, blank=True, default="")
    breaking_until = models.DateTimeField(null=True)
    # A live blog is live from its first publication until an editor ends it.
    live_ended_at = models.DateTimeField(null=True)
    engagement = models.JSONField(default=dict)
    scheduled_at = models.DateTimeField(null=True)
    embargo_until = models.DateTimeField(null=True)
    first_published_at = models.DateTimeField(null=True)
    published_at = models.DateTimeField(null=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    locked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="+"
    )
    locked_at = models.DateTimeField(null=True)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=~Q(status="scheduled") | Q(scheduled_at__isnull=False),
                name="post_scheduled_has_time",
            ),
            models.CheckConstraint(
                condition=~Q(status="published") | Q(published_at__isnull=False),
                name="post_published_has_time",
            ),
            models.CheckConstraint(
                condition=Q(youtube_id="") | Q(youtube_id__regex=r"^[A-Za-z0-9_-]{11}$"),
                name="post_youtube_id",
            ),
        ]
        indexes = [
            models.Index(fields=["status", "-updated_at"]),
            models.Index(fields=["category", "-updated_at"]),
            models.Index(fields=["scheduled_at"], condition=Q(status="scheduled"), name="post_due"),
        ]

    def __str__(self) -> str:
        return f"{self.type} {self.pk}"

    def rbac_scopes(self) -> list[tuple[str, str]]:
        # The primary category decides. Otherwise adding a secondary category would hand over editing rights.
        return [("category", str(self.category_id))]


class PostAuthor(BaseModel):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="bylines")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="bylines")
    position = models.PositiveSmallIntegerField(default=0)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["post", "user"], name="post_author_unique")]
        ordering = ["position"]

    def __str__(self) -> str:
        return f"{self.post_id} {self.user_id}"


class PostText(BaseModel):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="texts")
    locale = models.CharField(max_length=5, choices=Locale)
    headline = models.CharField(max_length=200, blank=True, default="")
    standfirst = models.CharField(max_length=400, blank=True, default="")
    slug = models.SlugField(max_length=100, blank=True, default="")
    body = models.JSONField(default=dict)
    seo_title = models.CharField(max_length=120, blank=True, default="")
    seo_description = models.CharField(max_length=320, blank=True, default="")
    focus_keyword = models.CharField(max_length=80, blank=True, default="")
    update_note = models.CharField(max_length=400, blank=True, default="")
    correction_note = models.CharField(max_length=600, blank=True, default="")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["post", "locale"], name="post_text_unique"),
            models.UniqueConstraint(
                fields=["locale", "slug"], condition=~Q(slug=""), name="post_slug_unique"
            ),
        ]

    def __str__(self) -> str:
        return f"{self.locale}:{self.slug}"


class AuthorProfile(BaseModel):
    """The public face of a member of staff. Made with their first publication; their own to edit."""

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="author")
    slug = models.SlugField(max_length=80, unique=True)
    title_sw = models.CharField(max_length=120, blank=True, default="")
    title_en = models.CharField(max_length=120, blank=True, default="")
    bio_sw = models.TextField(max_length=2000, blank=True, default="")
    bio_en = models.TextField(max_length=2000, blank=True, default="")
    expertise = ArrayField(models.CharField(max_length=60), default=list)
    links = ArrayField(models.URLField(max_length=300), default=list)
    avatar = models.ForeignKey("media.Asset", null=True, on_delete=models.PROTECT, related_name="avatar_of")

    def __str__(self) -> str:
        return self.slug


class RevisionKind(models.TextChoices):
    AUTOSAVE = "autosave"
    SAVE = "save"
    RESTORE = "restore"
    PUBLISH = "publish"


class Revision(BaseModel):
    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="revisions")
    number = models.PositiveIntegerField()
    kind = models.CharField(max_length=10, choices=RevisionKind)
    snapshot = models.JSONField()
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    note = models.CharField(max_length=300, blank=True, default="")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["post", "number"], name="revision_unique")]
        ordering = ["-number"]

    def __str__(self) -> str:
        return f"{self.post_id} r{self.number}"


class EditorialNote(BaseModel):
    """The conversation between a journalist and an editor. Never public."""

    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="notes")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="+")
    text = models.CharField(max_length=2000)
    transition = models.CharField(max_length=40, blank=True, default="")

    def __str__(self) -> str:
        return f"{self.post_id} {self.author_id}"


class Publication(BaseModel):
    """What readers get, one row per language, complete. Written only by content.publishing."""

    post = models.ForeignKey(Post, on_delete=models.CASCADE, related_name="publications")
    locale = models.CharField(max_length=5, choices=Locale)
    path = models.CharField(max_length=300)
    slug = models.SlugField(max_length=100)
    type = models.CharField(max_length=20, choices=PostType)
    category = models.ForeignKey("taxonomy.Category", on_delete=models.PROTECT, related_name="publications")
    published_at = models.DateTimeField()
    modified_at = models.DateTimeField()
    breaking_until = models.DateTimeField(null=True)
    is_live = models.BooleanField(default=False)
    card = models.JSONField()
    article = models.JSONField()
    etag = models.CharField(max_length=64)
    asset_ids = ArrayField(models.UUIDField(), default=list)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["post", "locale"], name="publication_unique"),
            models.UniqueConstraint(fields=["locale", "slug"], name="publication_slug_unique"),
            models.UniqueConstraint(fields=["path"], name="publication_path_unique"),
        ]
        indexes = [
            models.Index(fields=["locale", "-published_at"]),
            models.Index(
                fields=["locale", "breaking_until"],
                condition=Q(breaking_until__isnull=False),
                name="publication_breaking",
            ),
            models.Index(
                fields=["locale", "-published_at"], condition=Q(is_live=True), name="publication_live"
            ),
        ]

    def __str__(self) -> str:
        return self.path


class Feed(models.TextChoices):
    ALL = "all"
    TYPE = "type"
    CATEGORY = "category"
    TAG = "tag"
    STORY = "story"
    AUTHOR = "author"


class Listing(models.Model):
    """Every feed is one range scan over this index: no joins, no sorting."""

    publication = models.ForeignKey(Publication, on_delete=models.CASCADE, related_name="listings")
    locale = models.CharField(max_length=5)
    feed = models.CharField(max_length=10, choices=Feed)
    key = models.CharField(max_length=40, blank=True, default="")
    published_at = models.DateTimeField()

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["publication", "feed", "key"], name="listing_unique"),
        ]
        indexes = [
            models.Index(
                F("locale"),
                F("feed"),
                F("key"),
                F("published_at").desc(),
                F("publication_id").desc(),
                name="listing_feed",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.feed}:{self.key}"
