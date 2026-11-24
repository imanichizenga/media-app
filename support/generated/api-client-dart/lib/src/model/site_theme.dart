//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/schemes.dart';
import 'package:news_api_client/src/model/site_theme_tokens.dart';
import 'package:news_api_client/src/model/theme_key_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_theme.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteTheme {
  /// Returns a new [SiteTheme] instance.
  SiteTheme({
    required this.schemaVersion,
    required this.hash,
    required this.key,
    required this.color,
    required this.darkColor,
    required this.css,
    required this.themeColor,
    required this.tokens,
  });

  @JsonKey(
    name: r'schema_version',
    required: true,
    includeIfNull: false,
  )
  final int schemaVersion;

  @JsonKey(
    name: r'hash',
    required: true,
    includeIfNull: false,
  )
  final String hash;

  @JsonKey(
    name: r'key',
    required: true,
    includeIfNull: false,
  )
  final ThemeKeyEnum key;

  @JsonKey(
    name: r'color',
    required: true,
    includeIfNull: false,
  )
  final String color;

  @JsonKey(
    name: r'dark_color',
    required: true,
    includeIfNull: false,
  )
  final String darkColor;

  @JsonKey(
    name: r'css',
    required: true,
    includeIfNull: false,
  )
  final String css;

  @JsonKey(
    name: r'theme_color',
    required: true,
    includeIfNull: false,
  )
  final Schemes themeColor;

  @JsonKey(
    name: r'tokens',
    required: true,
    includeIfNull: false,
  )
  final SiteThemeTokens tokens;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteTheme &&
          other.schemaVersion == schemaVersion &&
          other.hash == hash &&
          other.key == key &&
          other.color == color &&
          other.darkColor == darkColor &&
          other.css == css &&
          other.themeColor == themeColor &&
          other.tokens == tokens;

  @override
  int get hashCode =>
      schemaVersion.hashCode +
      hash.hashCode +
      key.hashCode +
      color.hashCode +
      darkColor.hashCode +
      css.hashCode +
      themeColor.hashCode +
      tokens.hashCode;

  factory SiteTheme.fromJson(Map<String, dynamic> json) =>
      _$SiteThemeFromJson(json);

  Map<String, dynamic> toJson() => _$SiteThemeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
