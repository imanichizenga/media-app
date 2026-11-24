//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/site_localization.dart';
import 'package:news_api_client/src/model/site_identity.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_config.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteConfig {
  /// Returns a new [SiteConfig] instance.
  SiteConfig({
    required this.version,
    required this.mediaBaseUrl,
    required this.identity,
    required this.localization,
  });

  @JsonKey(
    name: r'version',
    required: true,
    includeIfNull: false,
  )
  final String version;

  @JsonKey(
    name: r'media_base_url',
    required: true,
    includeIfNull: false,
  )
  final String mediaBaseUrl;

  @JsonKey(
    name: r'identity',
    required: true,
    includeIfNull: false,
  )
  final SiteIdentity identity;

  @JsonKey(
    name: r'localization',
    required: true,
    includeIfNull: false,
  )
  final SiteLocalization localization;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteConfig &&
          other.version == version &&
          other.mediaBaseUrl == mediaBaseUrl &&
          other.identity == identity &&
          other.localization == localization;

  @override
  int get hashCode =>
      version.hashCode +
      mediaBaseUrl.hashCode +
      identity.hashCode +
      localization.hashCode;

  factory SiteConfig.fromJson(Map<String, dynamic> json) =>
      _$SiteConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SiteConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
