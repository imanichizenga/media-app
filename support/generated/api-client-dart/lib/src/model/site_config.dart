//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/site_apps.dart';
import 'package:news_api_client/src/model/site_localization.dart';
import 'package:news_api_client/src/model/site_identity.dart';
import 'package:news_api_client/src/model/site_theme.dart';
import 'package:news_api_client/src/model/site_seo.dart';
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
    required this.theme,
    required this.identity,
    required this.version,
    required this.mediaBaseUrl,
    required this.localization,
    required this.seo,
    required this.apps,
  });

  @JsonKey(
    name: r'theme',
    required: true,
    includeIfNull: false,
  )
  final SiteTheme theme;

  @JsonKey(
    name: r'identity',
    required: true,
    includeIfNull: false,
  )
  final SiteIdentity identity;

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
    name: r'localization',
    required: true,
    includeIfNull: false,
  )
  final SiteLocalization localization;

  @JsonKey(
    name: r'seo',
    required: true,
    includeIfNull: false,
  )
  final SiteSeo seo;

  @JsonKey(
    name: r'apps',
    required: true,
    includeIfNull: false,
  )
  final SiteApps apps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteConfig &&
          other.theme == theme &&
          other.identity == identity &&
          other.version == version &&
          other.mediaBaseUrl == mediaBaseUrl &&
          other.localization == localization &&
          other.seo == seo &&
          other.apps == apps;

  @override
  int get hashCode =>
      theme.hashCode +
      identity.hashCode +
      version.hashCode +
      mediaBaseUrl.hashCode +
      localization.hashCode +
      seo.hashCode +
      apps.hashCode;

  factory SiteConfig.fromJson(Map<String, dynamic> json) =>
      _$SiteConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SiteConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
