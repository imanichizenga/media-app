//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/page_translation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicPage {
  /// Returns a new [PublicPage] instance.
  PublicPage({
    required this.key,
    required this.locale,
    required this.path,
    required this.title,
    required this.summary,
    required this.body,
    required this.assets,
    required this.publishedAt,
    required this.modifiedAt,
    required this.translations,
  });

  @JsonKey(
    name: r'key',
    required: true,
    includeIfNull: false,
  )
  final String key;

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
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'summary',
    required: true,
    includeIfNull: false,
  )
  final String summary;

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
    name: r'translations',
    required: true,
    includeIfNull: false,
  )
  final List<PageTranslation> translations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicPage &&
          other.key == key &&
          other.locale == locale &&
          other.path == path &&
          other.title == title &&
          other.summary == summary &&
          other.body == body &&
          other.assets == assets &&
          other.publishedAt == publishedAt &&
          other.modifiedAt == modifiedAt &&
          other.translations == translations;

  @override
  int get hashCode =>
      key.hashCode +
      locale.hashCode +
      path.hashCode +
      title.hashCode +
      summary.hashCode +
      body.hashCode +
      assets.hashCode +
      publishedAt.hashCode +
      modifiedAt.hashCode +
      translations.hashCode;

  factory PublicPage.fromJson(Map<String, dynamic> json) =>
      _$PublicPageFromJson(json);

  Map<String, dynamic> toJson() => _$PublicPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
