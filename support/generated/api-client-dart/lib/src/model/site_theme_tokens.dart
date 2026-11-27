//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_theme_tokens.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteThemeTokens {
  /// Returns a new [SiteThemeTokens] instance.
  SiteThemeTokens({required this.light, required this.dark});

  @JsonKey(name: r'light', required: true, includeIfNull: false)
  final Map<String, String> light;

  @JsonKey(name: r'dark', required: true, includeIfNull: false)
  final Map<String, String> dark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteThemeTokens && other.light == light && other.dark == dark;

  @override
  int get hashCode => light.hashCode + dark.hashCode;

  factory SiteThemeTokens.fromJson(Map<String, dynamic> json) =>
      _$SiteThemeTokensFromJson(json);

  Map<String, dynamic> toJson() => _$SiteThemeTokensToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
