//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_category.dart';
import 'package:news_api_client/src/model/post_type_enum.dart';
import 'package:news_api_client/src/model/public_image.dart';
import 'package:news_api_client/src/model/public_video.dart';
import 'package:news_api_client/src/model/card_byline.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Card {
  /// Returns a new [Card] instance.
  Card({
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
  final List<CardByline> authors;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
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
          other.isLive == isLive;

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
      isLive.hashCode;

  factory Card.fromJson(Map<String, dynamic> json) => _$CardFromJson(json);

  Map<String, dynamic> toJson() => _$CardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
