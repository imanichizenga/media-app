// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteConfigCWProxy {
  SiteConfig theme(SiteTheme theme);

  SiteConfig identity(SiteIdentity identity);

  SiteConfig version(String version);

  SiteConfig mediaBaseUrl(String mediaBaseUrl);

  SiteConfig localization(SiteLocalization localization);

  SiteConfig seo(SiteSeo seo);

  SiteConfig apps(SiteApps apps);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteConfig call({
    SiteTheme theme,
    SiteIdentity identity,
    String version,
    String mediaBaseUrl,
    SiteLocalization localization,
    SiteSeo seo,
    SiteApps apps,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteConfig.copyWith.fieldName(...)`
class _$SiteConfigCWProxyImpl implements _$SiteConfigCWProxy {
  const _$SiteConfigCWProxyImpl(this._value);

  final SiteConfig _value;

  @override
  SiteConfig theme(SiteTheme theme) => this(theme: theme);

  @override
  SiteConfig identity(SiteIdentity identity) => this(identity: identity);

  @override
  SiteConfig version(String version) => this(version: version);

  @override
  SiteConfig mediaBaseUrl(String mediaBaseUrl) =>
      this(mediaBaseUrl: mediaBaseUrl);

  @override
  SiteConfig localization(SiteLocalization localization) =>
      this(localization: localization);

  @override
  SiteConfig seo(SiteSeo seo) => this(seo: seo);

  @override
  SiteConfig apps(SiteApps apps) => this(apps: apps);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteConfig call({
    Object? theme = const $CopyWithPlaceholder(),
    Object? identity = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? mediaBaseUrl = const $CopyWithPlaceholder(),
    Object? localization = const $CopyWithPlaceholder(),
    Object? seo = const $CopyWithPlaceholder(),
    Object? apps = const $CopyWithPlaceholder(),
  }) {
    return SiteConfig(
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
      localization: localization == const $CopyWithPlaceholder()
          ? _value.localization
          // ignore: cast_nullable_to_non_nullable
          : localization as SiteLocalization,
      seo: seo == const $CopyWithPlaceholder()
          ? _value.seo
          // ignore: cast_nullable_to_non_nullable
          : seo as SiteSeo,
      apps: apps == const $CopyWithPlaceholder()
          ? _value.apps
          // ignore: cast_nullable_to_non_nullable
          : apps as SiteApps,
    );
  }
}

extension $SiteConfigCopyWith on SiteConfig {
  /// Returns a callable class that can be used as follows: `instanceOfSiteConfig.copyWith(...)` or like so:`instanceOfSiteConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteConfigCWProxy get copyWith => _$SiteConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteConfig _$SiteConfigFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SiteConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'theme',
            'identity',
            'version',
            'media_base_url',
            'localization',
            'seo',
            'apps'
          ],
        );
        final val = SiteConfig(
          theme: $checkedConvert(
              'theme', (v) => SiteTheme.fromJson(v as Map<String, dynamic>)),
          identity: $checkedConvert('identity',
              (v) => SiteIdentity.fromJson(v as Map<String, dynamic>)),
          version: $checkedConvert('version', (v) => v as String),
          mediaBaseUrl: $checkedConvert('media_base_url', (v) => v as String),
          localization: $checkedConvert('localization',
              (v) => SiteLocalization.fromJson(v as Map<String, dynamic>)),
          seo: $checkedConvert(
              'seo', (v) => SiteSeo.fromJson(v as Map<String, dynamic>)),
          apps: $checkedConvert(
              'apps', (v) => SiteApps.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'mediaBaseUrl': 'media_base_url'},
    );

Map<String, dynamic> _$SiteConfigToJson(SiteConfig instance) =>
    <String, dynamic>{
      'theme': instance.theme.toJson(),
      'identity': instance.identity.toJson(),
      'version': instance.version,
      'media_base_url': instance.mediaBaseUrl,
      'localization': instance.localization.toJson(),
      'seo': instance.seo.toJson(),
      'apps': instance.apps.toJson(),
    };
