//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_category.dart';
import 'package:news_api_client/src/model/public_seo.dart';
import 'package:news_api_client/src/model/related_target.dart';
import 'package:news_api_client/src/model/post_type_enum.dart';
import 'package:news_api_client/src/model/public_policy.dart';
import 'package:news_api_client/src/model/public_region.dart';
import 'package:news_api_client/src/model/public_story_ref.dart';
import 'package:news_api_client/src/model/translation.dart';
import 'package:news_api_client/src/model/public_byline.dart';
import 'package:news_api_client/src/model/public_image.dart';
import 'package:news_api_client/src/model/public_video.dart';
import 'package:news_api_client/src/model/public_label.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'article.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Article {
  /// Returns a new [Article] instance.
  Article({
    required this.id,
    required this.type,
    required this.locale,
    required this.path,
    required this.slug,
    required this.headline,
    required this.standfirst,
    required this.category,
    required this.authors,
    required this.image,
    required this.video,
    required this.youtubeId,
    required this.readingMinutes,
    required this.publishedAt,
    required this.modifiedAt,
    required this.isSensitive,
    required this.breakingUntil,
    required this.isLive,
    required this.body,
    required this.assets,
    required this.links,
    required this.breadcrumbs,
    required this.tags,
    required this.regions,
    required this.story,
    required this.engagement,
    required this.contentWarning,
    required this.sourceUrl,
    required this.updateNote,
    required this.correctionNote,
    required this.seo,
    required this.firstPublishedAt,
    required this.liveEndedAt,
    required this.translations,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'type',
    required: true,
    includeIfNull: false,
  )
  final PostTypeEnum type;

  @JsonKey(
    name: r'locale',
    required: true,
    includeIfNull: false,
  )
  final String locale;

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @JsonKey(
    name: r'slug',
    required: true,
    includeIfNull: false,
  )
  final String slug;

  @JsonKey(
    name: r'headline',
    required: true,
    includeIfNull: false,
  )
  final String headline;

  @JsonKey(
    name: r'standfirst',
    required: true,
    includeIfNull: false,
  )
  final String standfirst;

  @JsonKey(
    name: r'category',
    required: true,
    includeIfNull: false,
  )
  final PublicCategory category;

  @JsonKey(
    name: r'authors',
    required: true,
    includeIfNull: false,
  )
  final List<PublicByline> authors;

  @JsonKey(
    name: r'image',
    required: true,
    includeIfNull: true,
  )
  final PublicImage? image;

  @JsonKey(
    name: r'video',
    required: true,
    includeIfNull: true,
  )
  final PublicVideo? video;

  @JsonKey(
    name: r'youtube_id',
    required: true,
    includeIfNull: false,
  )
  final String youtubeId;

  @JsonKey(
    name: r'reading_minutes',
    required: true,
    includeIfNull: false,
  )
  final int readingMinutes;

  @JsonKey(
    name: r'published_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime publishedAt;

  @JsonKey(
    name: r'modified_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime modifiedAt;

  @JsonKey(
    name: r'is_sensitive',
    required: true,
    includeIfNull: false,
  )
  final bool isSensitive;

  @JsonKey(
    name: r'breaking_until',
    required: true,
    includeIfNull: true,
  )
  final DateTime? breakingUntil;

  @JsonKey(
    name: r'is_live',
    required: true,
    includeIfNull: false,
  )
  final bool isLive;

  @JsonKey(
    name: r'body',
    required: true,
    includeIfNull: false,
  )
  final Map<String, Object?> body;

  @JsonKey(
    name: r'assets',
    required: true,
    includeIfNull: false,
  )
  final Map<String, Map<String, Object?>> assets;

  @JsonKey(
    name: r'links',
    required: true,
    includeIfNull: false,
  )
  final Map<String, RelatedTarget> links;

  @JsonKey(
    name: r'breadcrumbs',
    required: true,
    includeIfNull: false,
  )
  final List<PublicCategory> breadcrumbs;

  @JsonKey(
    name: r'tags',
    required: true,
    includeIfNull: false,
  )
  final List<PublicLabel> tags;

  @JsonKey(
    name: r'regions',
    required: true,
    includeIfNull: false,
  )
  final List<PublicRegion> regions;

  @JsonKey(
    name: r'story',
    required: true,
    includeIfNull: true,
  )
  final PublicStoryRef? story;

  @JsonKey(
    name: r'engagement',
    required: true,
    includeIfNull: false,
  )
  final PublicPolicy engagement;

  @JsonKey(
    name: r'content_warning',
    required: true,
    includeIfNull: false,
  )
  final String contentWarning;

  @JsonKey(
    name: r'source_url',
    required: true,
    includeIfNull: false,
  )
  final String sourceUrl;

  @JsonKey(
    name: r'update_note',
    required: true,
    includeIfNull: false,
  )
  final String updateNote;

  @JsonKey(
    name: r'correction_note',
    required: true,
    includeIfNull: false,
  )
  final String correctionNote;

  @JsonKey(
    name: r'seo',
    required: true,
    includeIfNull: false,
  )
  final PublicSeo seo;

  @JsonKey(
    name: r'first_published_at',
    required: true,
    includeIfNull: true,
  )
  final DateTime? firstPublishedAt;

  @JsonKey(
    name: r'live_ended_at',
    required: true,
    includeIfNull: true,
  )
  final DateTime? liveEndedAt;

  @JsonKey(
    name: r'translations',
    required: true,
    includeIfNull: false,
  )
  final List<Translation> translations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article &&
          other.id == id &&
          other.type == type &&
          other.locale == locale &&
          other.path == path &&
          other.slug == slug &&
          other.headline == headline &&
          other.standfirst == standfirst &&
          other.category == category &&
          other.authors == authors &&
          other.image == image &&
          other.video == video &&
          other.youtubeId == youtubeId &&
          other.readingMinutes == readingMinutes &&
          other.publishedAt == publishedAt &&
          other.modifiedAt == modifiedAt &&
          other.isSensitive == isSensitive &&
          other.breakingUntil == breakingUntil &&
          other.isLive == isLive &&
          other.body == body &&
          other.assets == assets &&
          other.links == links &&
          other.breadcrumbs == breadcrumbs &&
          other.tags == tags &&
          other.regions == regions &&
          other.story == story &&
          other.engagement == engagement &&
          other.contentWarning == contentWarning &&
          other.sourceUrl == sourceUrl &&
          other.updateNote == updateNote &&
          other.correctionNote == correctionNote &&
          other.seo == seo &&
          other.firstPublishedAt == firstPublishedAt &&
          other.liveEndedAt == liveEndedAt &&
          other.translations == translations;

  @override
  int get hashCode =>
      id.hashCode +
      type.hashCode +
      locale.hashCode +
      path.hashCode +
      slug.hashCode +
      headline.hashCode +
      standfirst.hashCode +
      category.hashCode +
      authors.hashCode +
      (image == null ? 0 : image.hashCode) +
      (video == null ? 0 : video.hashCode) +
      youtubeId.hashCode +
      readingMinutes.hashCode +
      publishedAt.hashCode +
      modifiedAt.hashCode +
      isSensitive.hashCode +
      (breakingUntil == null ? 0 : breakingUntil.hashCode) +
      isLive.hashCode +
      body.hashCode +
      assets.hashCode +
      links.hashCode +
      breadcrumbs.hashCode +
      tags.hashCode +
      regions.hashCode +
      (story == null ? 0 : story.hashCode) +
      engagement.hashCode +
      contentWarning.hashCode +
      sourceUrl.hashCode +
      updateNote.hashCode +
      correctionNote.hashCode +
      seo.hashCode +
      (firstPublishedAt == null ? 0 : firstPublishedAt.hashCode) +
      (liveEndedAt == null ? 0 : liveEndedAt.hashCode) +
      translations.hashCode;

  factory Article.fromJson(Map<String, dynamic> json) =>
      _$ArticleFromJson(json);

  Map<String, dynamic> toJson() => _$ArticleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
