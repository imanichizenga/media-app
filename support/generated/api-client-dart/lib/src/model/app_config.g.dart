// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppConfigCWProxy {
  AppConfig theme(SiteTheme theme);

  AppConfig identity(SiteIdentity identity);

  AppConfig version(String version);

  AppConfig mediaBaseUrl(String mediaBaseUrl);

  AppConfig versions(AppVersions versions);

  AppConfig maintenance(AppMaintenance maintenance);

  AppConfig flags(AppFlags flags);

  AppConfig links(AppLinks links);

  AppConfig pinning(AppPinning pinning);

  AppConfig localization(AppLocalization localization);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  AppConfig call({
    SiteTheme theme,
    SiteIdentity identity,
    String version,
    String mediaBaseUrl,
    AppVersions versions,
    AppMaintenance maintenance,
    AppFlags flags,
    AppLinks links,
    AppPinning pinning,
    AppLocalization localization,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppConfig.copyWith.fieldName(...)`
class _$AppConfigCWProxyImpl implements _$AppConfigCWProxy {
  const _$AppConfigCWProxyImpl(this._value);

  final AppConfig _value;

  @override
  AppConfig theme(SiteTheme theme) => this(theme: theme);

  @override
  AppConfig identity(SiteIdentity identity) => this(identity: identity);

  @override
  AppConfig version(String version) => this(version: version);

  @override
  AppConfig mediaBaseUrl(String mediaBaseUrl) =>
      this(mediaBaseUrl: mediaBaseUrl);

  @override
  AppConfig versions(AppVersions versions) => this(versions: versions);

  @override
  AppConfig maintenance(AppMaintenance maintenance) =>
      this(maintenance: maintenance);

  @override
  AppConfig flags(AppFlags flags) => this(flags: flags);

  @override
  AppConfig links(AppLinks links) => this(links: links);

  @override
  AppConfig pinning(AppPinning pinning) => this(pinning: pinning);

  @override
  AppConfig localization(AppLocalization localization) =>
      this(localization: localization);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  AppConfig call({
    Object? theme = const $CopyWithPlaceholder(),
    Object? identity = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? mediaBaseUrl = const $CopyWithPlaceholder(),
    Object? versions = const $CopyWithPlaceholder(),
    Object? maintenance = const $CopyWithPlaceholder(),
    Object? flags = const $CopyWithPlaceholder(),
    Object? links = const $CopyWithPlaceholder(),
    Object? pinning = const $CopyWithPlaceholder(),
    Object? localization = const $CopyWithPlaceholder(),
  }) {
    return AppConfig(
      theme: theme == const $CopyWithPlaceholder()
          ? _value.theme
          // ignore: cast_nullable_to_non_nullable
          : theme as SiteTheme,
      identity: identity == const $CopyWithPlaceholder()
          ? _value.identity
          // ignore: cast_nullable_to_non_nullable
          : identity as SiteIdentity,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      mediaBaseUrl: mediaBaseUrl == const $CopyWithPlaceholder()
          ? _value.mediaBaseUrl
          // ignore: cast_nullable_to_non_nullable
          : mediaBaseUrl as String,
      versions: versions == const $CopyWithPlaceholder()
          ? _value.versions
          // ignore: cast_nullable_to_non_nullable
          : versions as AppVersions,
      maintenance: maintenance == const $CopyWithPlaceholder()
          ? _value.maintenance
          // ignore: cast_nullable_to_non_nullable
          : maintenance as AppMaintenance,
      flags: flags == const $CopyWithPlaceholder()
          ? _value.flags
          // ignore: cast_nullable_to_non_nullable
          : flags as AppFlags,
      links: links == const $CopyWithPlaceholder()
          ? _value.links
          // ignore: cast_nullable_to_non_nullable
          : links as AppLinks,
      pinning: pinning == const $CopyWithPlaceholder()
          ? _value.pinning
          // ignore: cast_nullable_to_non_nullable
          : pinning as AppPinning,
      localization: localization == const $CopyWithPlaceholder()
          ? _value.localization
          // ignore: cast_nullable_to_non_nullable
          : localization as AppLocalization,
    );
  }
}

extension $AppConfigCopyWith on AppConfig {
  /// Returns a callable class that can be used as follows: `instanceOfAppConfig.copyWith(...)` or like so:`instanceOfAppConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppConfigCWProxy get copyWith => _$AppConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppConfig _$AppConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppConfig', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'theme',
          'identity',
          'version',
          'media_base_url',
          'versions',
          'maintenance',
          'flags',
          'links',
          'pinning',
          'localization',
        ],
      );
      final val = AppConfig(
        theme: $checkedConvert(
          'theme',
          (v) => SiteTheme.fromJson(v as Map<String, dynamic>),
        ),
        identity: $checkedConvert(
          'identity',
          (v) => SiteIdentity.fromJson(v as Map<String, dynamic>),
        ),
        version: $checkedConvert('version', (v) => v as String),
        mediaBaseUrl: $checkedConvert('media_base_url', (v) => v as String),
        versions: $checkedConvert(
          'versions',
          (v) => AppVersions.fromJson(v as Map<String, dynamic>),
        ),
        maintenance: $checkedConvert(
          'maintenance',
          (v) => AppMaintenance.fromJson(v as Map<String, dynamic>),
        ),
        flags: $checkedConvert(
          'flags',
          (v) => AppFlags.fromJson(v as Map<String, dynamic>),
        ),
        links: $checkedConvert(
          'links',
          (v) => AppLinks.fromJson(v as Map<String, dynamic>),
        ),
        pinning: $checkedConvert(
          'pinning',
          (v) => AppPinning.fromJson(v as Map<String, dynamic>),
        ),
        localization: $checkedConvert(
          'localization',
          (v) => AppLocalization.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'mediaBaseUrl': 'media_base_url'});

Map<String, dynamic> _$AppConfigToJson(AppConfig instance) => <String, dynamic>{
  'theme': instance.theme.toJson(),
  'identity': instance.identity.toJson(),
  'version': instance.version,
  'media_base_url': instance.mediaBaseUrl,
  'versions': instance.versions.toJson(),
  'maintenance': instance.maintenance.toJson(),
  'flags': instance.flags.toJson(),
  'links': instance.links.toJson(),
  'pinning': instance.pinning.toJson(),
  'localization': instance.localization.toJson(),
};
