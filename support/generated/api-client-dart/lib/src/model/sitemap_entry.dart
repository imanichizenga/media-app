//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/sitemap_translation.dart';
import 'package:news_api_client/src/model/public_image.dart';
import 'package:news_api_client/src/model/public_video.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sitemap_entry.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SitemapEntry {
  /// Returns a new [SitemapEntry] instance.
  SitemapEntry({
    required this.path,

    required this.locale,

    required this.type,

    required this.headline,

    required this.standfirst,

    required this.publishedAt,

    required this.modifiedAt,

    required this.image,

    required this.video,

    required this.youtubeId,

    required this.durationMs,

    required this.isSensitive,

    required this.translations,
  });

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @JsonKey(name: r'locale', required: true, includeIfNull: false)
  final String locale;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final String type;

  @JsonKey(name: r'headline', required: true, includeIfNull: false)
  final String headline;

  @JsonKey(name: r'standfirst', required: true, includeIfNull: false)
  final String standfirst;

  @JsonKey(name: r'published_at', required: true, includeIfNull: false)
  final DateTime publishedAt;

  @JsonKey(name: r'modified_at', required: true, includeIfNull: false)
  final DateTime modifiedAt;

  @JsonKey(name: r'image', required: true, includeIfNull: true)
  final PublicImage? image;

  @JsonKey(name: r'video', required: true, includeIfNull: true)
  final PublicVideo? video;

  @JsonKey(name: r'youtube_id', required: true, includeIfNull: false)
  final String youtubeId;

  @JsonKey(name: r'duration_ms', required: true, includeIfNull: true)
  final int? durationMs;

  @JsonKey(name: r'is_sensitive', required: true, includeIfNull: false)
  final bool isSensitive;

  @JsonKey(name: r'translations', required: true, includeIfNull: false)
  final List<SitemapTranslation> translations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SitemapEntry &&
          other.path == path &&
          other.locale == locale &&
          other.type == type &&
          other.headline == headline &&
          other.standfirst == standfirst &&
          other.publishedAt == publishedAt &&
          other.modifiedAt == modifiedAt &&
          other.image == image &&
          other.video == video &&
          other.youtubeId == youtubeId &&
          other.durationMs == durationMs &&
          other.isSensitive == isSensitive &&
          other.translations == translations;

  @override
  int get hashCode =>
      path.hashCode +
      locale.hashCode +
      type.hashCode +
      headline.hashCode +
      standfirst.hashCode +
      publishedAt.hashCode +
      modifiedAt.hashCode +
      (image == null ? 0 : image.hashCode) +
      (video == null ? 0 : video.hashCode) +
      youtubeId.hashCode +
      (durationMs == null ? 0 : durationMs.hashCode) +
      isSensitive.hashCode +
      translations.hashCode;

  factory SitemapEntry.fromJson(Map<String, dynamic> json) =>
      _$SitemapEntryFromJson(json);

  Map<String, dynamic> toJson() => _$SitemapEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
