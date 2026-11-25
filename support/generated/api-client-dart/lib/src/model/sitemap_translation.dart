//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sitemap_translation.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SitemapTranslation {
  /// Returns a new [SitemapTranslation] instance.
  SitemapTranslation({
    required this.locale,
    required this.path,
  });

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SitemapTranslation &&
          other.locale == locale &&
          other.path == path;

  @override
  int get hashCode => locale.hashCode + path.hashCode;

  factory SitemapTranslation.fromJson(Map<String, dynamic> json) =>
      _$SitemapTranslationFromJson(json);

  Map<String, dynamic> toJson() => _$SitemapTranslationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
