from django.contrib.postgres.fields import ArrayField
from django.contrib.postgres.indexes import GinIndex
from django.core.validators import RegexValidator
from django.db import models
from django.db.models import Q

from newsplatform.common.locales import Locale
from newsplatform.common.models import BaseModel

MAX_DEPTH = 3


class Visibility(models.TextChoices):
    PUBLIC = "public"
    HIDDEN = "hidden"
    ARCHIVED = "archived"


class Category(BaseModel):
    parent = models.ForeignKey("self", null=True, on_delete=models.PROTECT, related_name="children")
    depth = models.PositiveSmallIntegerField(default=1)
    # Every ancestor, root first. Moving a branch rewrites it, so reads never walk the tree.
    ancestors = ArrayField(models.UUIDField(), default=list)
    position = models.PositiveIntegerField(default=0)
    icon = models.SlugField(max_length=40, blank=True, default="")
    color = models.CharField(
        max_length=7, blank=True, default="", validators=[RegexValidator(r"^#[0-9a-f]{6}\Z")]
    )
    visibility = models.CharField(max_length=10, choices=Visibility, default=Visibility.PUBLIC)
    # Partial: only the fields this category overrides (engagement.policy).
    engagement = models.JSONField(default=dict)
    version = models.PositiveIntegerField(default=1)

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=Q(depth__gte=1) & Q(depth__lte=MAX_DEPTH), name="category_depth"
            ),
            models.CheckConstraint(
                condition=(Q(parent__isnull=True) & Q(depth=1)) | (Q(parent__isnull=False) & Q(depth__gt=1)),
                name="category_root_depth",
            ),
            models.CheckConstraint(
                condition=Q(color="") | Q(color__regex=r"^#[0-9a-f]{6}$"), name="category_color"
            ),
        ]
        indexes = [models.Index(fields=["parent", "position"]), GinIndex(fields=["ancestors"])]

    def __str__(self) -> str:
        return str(self.id)

    def rbac_scopes(self) -> list[tuple[str, str]]:
        return [("category", str(self.pk))]


class CategoryText(BaseModel):
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name="texts")
    locale = models.CharField(max_length=5, choices=Locale)
    name = models.CharField(max_length=80)
    slug = models.SlugField(max_length=80)
    description = models.CharField(max_length=500, blank=True, default="")
    seo_title = models.CharField(max_length=120, blank=True, default="")
    seo_description = models.CharField(max_length=320, blank=True, default="")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["category", "locale"], name="category_text_unique"),
            models.UniqueConstraint(fields=["locale", "slug"], name="category_slug_unique"),
        ]

    def __str__(self) -> str:
        return f"{self.locale}:{self.slug}"


class Tag(BaseModel):
    slug = models.SlugField(max_length=80, unique=True)
    name_sw = models.CharField(max_length=80)
    name_en = models.CharField(max_length=80)
    # Lower-cased words that editors and imports may type instead.
    synonyms = ArrayField(models.CharField(max_length=80), default=list)
    merged_into = models.ForeignKey("self", null=True, on_delete=models.PROTECT, related_name="merged")

    class Meta:
        indexes = [GinIndex(fields=["synonyms"])]

    def __str__(self) -> str:
        return self.slug


class Region(BaseModel):
    slug = models.SlugField(max_length=80, unique=True)
    name_sw = models.CharField(max_length=80)
    name_en = models.CharField(max_length=80)

    def __str__(self) -> str:
        return self.slug


class Story(BaseModel):
    """A cluster of posts about one ongoing event."""

    slug = models.SlugField(max_length=120, unique=True)
    title_sw = models.CharField(max_length=160)
    title_en = models.CharField(max_length=160)
    summary_sw = models.CharField(max_length=600, blank=True, default="")
    summary_en = models.CharField(max_length=600, blank=True, default="")
    is_active = models.BooleanField(default=True)

    def __str__(self) -> str:
        return self.slug
