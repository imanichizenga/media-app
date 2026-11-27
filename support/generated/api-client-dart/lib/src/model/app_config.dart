//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/app_pinning.dart';
import 'package:news_api_client/src/model/app_links.dart';
import 'package:news_api_client/src/model/site_identity.dart';
import 'package:news_api_client/src/model/app_flags.dart';
import 'package:news_api_client/src/model/app_versions.dart';
import 'package:news_api_client/src/model/app_localization.dart';
import 'package:news_api_client/src/model/site_theme.dart';
import 'package:news_api_client/src/model/app_maintenance.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_config.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppConfig {
  /// Returns a new [AppConfig] instance.
  AppConfig({
    required this.theme,

    required this.identity,

    required this.version,

    required this.mediaBaseUrl,

    required this.versions,

    required this.maintenance,

    required this.flags,

    required this.links,

    required this.pinning,

    required this.localization,
  });

  @JsonKey(name: r'theme', required: true, includeIfNull: false)
  final SiteTheme theme;

  @JsonKey(name: r'identity', required: true, includeIfNull: false)
  final SiteIdentity identity;

  @JsonKey(name: r'version', required: true, includeIfNull: false)
  final String version;

  @JsonKey(name: r'media_base_url', required: true, includeIfNull: false)
  final String mediaBaseUrl;

  @JsonKey(name: r'versions', required: true, includeIfNull: false)
  final AppVersions versions;

  @JsonKey(name: r'maintenance', required: true, includeIfNull: false)
  final AppMaintenance maintenance;

  @JsonKey(name: r'flags', required: true, includeIfNull: false)
  final AppFlags flags;

  @JsonKey(name: r'links', required: true, includeIfNull: false)
  final AppLinks links;

  @JsonKey(name: r'pinning', required: true, includeIfNull: false)
  final AppPinning pinning;

  @JsonKey(name: r'localization', required: true, includeIfNull: false)
  final AppLocalization localization;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          other.theme == theme &&
          other.identity == identity &&
          other.version == version &&
          other.mediaBaseUrl == mediaBaseUrl &&
          other.versions == versions &&
          other.maintenance == maintenance &&
          other.flags == flags &&
          other.links == links &&
          other.pinning == pinning &&
          other.localization == localization;

  @override
  int get hashCode =>
      theme.hashCode +
      identity.hashCode +
      version.hashCode +
      mediaBaseUrl.hashCode +
      versions.hashCode +
      maintenance.hashCode +
      flags.hashCode +
      links.hashCode +
      pinning.hashCode +
      localization.hashCode;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AppConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
