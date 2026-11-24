"""The documented shape of public responses: the source of the generated TypeScript and Dart clients."""

from typing import Any

from rest_framework import serializers

from newsplatform.common.api import schema
from newsplatform.content.models import PostType
from newsplatform.engagement.policy import CommentMode


def _text(**kw: Any) -> Any:
    return serializers.CharField(allow_blank=True, **kw)


def _when(**kw: Any) -> Any:
    return serializers.DateTimeField(allow_null=True, **kw)


class PublicImageSerializer(serializers.Serializer[Any]):
    """Relative to `media_base_url` in site-config: `<base><width>.<avif|webp|jpg>`, and for sharing
    `<crops>crop-<16x9|4x3|1x1>.jpg`."""

    kind = serializers.ChoiceField(choices=["image"])
    id = serializers.UUIDField()
    alt = _text()
    credit = _text()
    width = serializers.IntegerField(allow_null=True)
    height = serializers.IntegerField(allow_null=True)
    blurhash = _text()
    color = _text()
    focal = serializers.ListField(child=serializers.IntegerField())
    base = _text()
    widths = serializers.ListField(child=serializers.IntegerField())
    crops = _text()


class PublicVideoSerializer(serializers.Serializer[Any]):
    kind = serializers.ChoiceField(choices=["video"])
    id = serializers.UUIDField()
    alt = _text()
    credit = _text()
    width = serializers.IntegerField(allow_null=True)
    height = serializers.IntegerField(allow_null=True)
    blurhash = _text()
    color = _text()
    duration_ms = serializers.IntegerField(allow_null=True)
    hls = _text()
    poster = _text()
    sprite = _text()
    sprite_vtt = _text()


class PublicCategorySerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    name = serializers.CharField()
    slug = serializers.CharField()
    path = serializers.CharField()
    color = _text()


class CardBylineSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    name = serializers.CharField()
    slug = serializers.CharField()
    path = serializers.CharField()


class PublicBylineSerializer(CardBylineSerializer):
    title = _text()
    avatar = PublicImageSerializer(allow_null=True)


class CardSerializer(serializers.Serializer[Any]):
    id = serializers.UUIDField()
    type = serializers.ChoiceField(choices=PostType.choices)
    locale = serializers.CharField()
    path = serializers.CharField()
    slug = serializers.CharField()
    headline = serializers.CharField()
    standfirst = _text()
    category = PublicCategorySerializer()
    authors = CardBylineSerializer(many=True)
    image = PublicImageSerializer(allow_null=True)
    video = PublicVideoSerializer(allow_null=True)
    youtube_id = _text()
    duration_ms = serializers.IntegerField(allow_null=True, help_text="Of the video, wherever it lives")
    reading_minutes = serializers.IntegerField()
    published_at = serializers.DateTimeField()
    modified_at = serializers.DateTimeField()
    is_sensitive = serializers.BooleanField()
    breaking_until = _when()
    is_live = serializers.BooleanField()


class PublicPolicySerializer(serializers.Serializer[Any]):
    likes = serializers.BooleanField()
    comments = serializers.ChoiceField(choices=[c.value for c in CommentMode])
    bookmarks = serializers.BooleanField()
    shares = serializers.BooleanField()
    reposts = serializers.BooleanField()
    live_chat = serializers.BooleanField()


class PublicLabelSerializer(serializers.Serializer[Any]):
    slug = serializers.CharField()
    name = serializers.CharField()
    path = serializers.CharField()


class ArticleSerializer(CardSerializer):
    """`body` is a content document (support/packages/content-schema); `assets` holds the files it names, by id."""

    authors = PublicBylineSerializer(many=True)
    body = serializers.DictField()
    assets = serializers.DictField(child=serializers.DictField())
    links = serializers.DictField(
        child=schema("RelatedTarget", path=serializers.CharField(), headline=serializers.CharField())
    )
    breadcrumbs = PublicCategorySerializer(many=True)
    tags = PublicLabelSerializer(many=True)
    regions = serializers.ListField(
        child=schema("PublicRegion", slug=serializers.CharField(), name=serializers.CharField())
    )
    story = schema(
        "PublicStoryRef",
        slug=serializers.CharField(),
        title=serializers.CharField(),
        path=serializers.CharField(),
    )
    engagement = PublicPolicySerializer()
    content_warning = _text()
    source_url = _text()
    update_note = _text()
    correction_note = _text()
    seo = schema("PublicSeo", title=serializers.CharField(), description=_text())
    first_published_at = _when()
    live_ended_at = _when()
    translations = serializers.ListField(
        child=schema("Translation", locale=serializers.CharField(), path=serializers.CharField())
    )

    def get_fields(self) -> Any:
        fields = super().get_fields()
        fields["story"].allow_null = True
        return fields


class FeedPageSerializer(serializers.Serializer[Any]):
    next_cursor = serializers.CharField(allow_null=True)
    results = CardSerializer(many=True)


class PublicCategoryDetailSerializer(PublicCategorySerializer):
    icon = _text()
    description = _text()
    seo_title = _text()
    seo_description = _text()
    parents = PublicCategorySerializer(many=True)
    children = PublicCategorySerializer(many=True)
    translations = serializers.ListField(
        child=schema("CategoryTranslation", locale=serializers.CharField(), path=serializers.CharField())
    )


class CategoryPageSerializer(FeedPageSerializer):
    category = PublicCategoryDetailSerializer()


class TagPageSerializer(FeedPageSerializer):
    tag = PublicLabelSerializer()


class StoryPageSerializer(FeedPageSerializer):
    story = schema(
        "PublicStory",
        slug=serializers.CharField(),
        title=serializers.CharField(),
        path=serializers.CharField(),
        summary=_text(),
        is_active=serializers.BooleanField(),
    )


class PublicAuthorSerializer(PublicBylineSerializer):
    bio = _text()
    expertise = serializers.ListField(child=serializers.CharField())
    links = serializers.ListField(child=serializers.CharField())


class AuthorPageSerializer(FeedPageSerializer):
    author = PublicAuthorSerializer()


class HomeSerializer(serializers.Serializer[Any]):
    breaking = CardSerializer(many=True)
    live = CardSerializer(many=True)
    lead = CardSerializer(many=True)
    latest = CardSerializer(many=True)
    videos = CardSerializer(many=True)
    shorts = CardSerializer(many=True)
    sections = serializers.ListField(
        child=schema("HomeSection", category=PublicCategorySerializer(), results=CardSerializer(many=True))
    )


class NavigationItemSerializer(PublicCategorySerializer):
    icon = _text()
    children = PublicCategorySerializer(many=True)


class RelatedSerializer(serializers.Serializer[Any]):
    results = CardSerializer(many=True)


class SearchSerializer(FeedPageSerializer):
    """Until search is connected (M8), `available` is false and nothing is found."""

    available = serializers.BooleanField()


class ResolveSerializer(serializers.Serializer[Any]):
    path = serializers.CharField()
