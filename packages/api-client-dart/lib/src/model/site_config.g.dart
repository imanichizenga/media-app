// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteConfigCWProxy {
  SiteConfig version(String version);

  SiteConfig identity(SiteIdentity identity);

  SiteConfig localization(SiteLocalization localization);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteConfig call({
    String version,
    SiteIdentity identity,
    SiteLocalization localization,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteConfig.copyWith.fieldName(...)`
class _$SiteConfigCWProxyImpl implements _$SiteConfigCWProxy {
  const _$SiteConfigCWProxyImpl(this._value);

  final SiteConfig _value;

  @override
  SiteConfig version(String version) => this(version: version);

  @override
  SiteConfig identity(SiteIdentity identity) => this(identity: identity);

  @override
  SiteConfig localization(SiteLocalization localization) =>
      this(localization: localization);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteConfig call({
    Object? version = const $CopyWithPlaceholder(),
    Object? identity = const $CopyWithPlaceholder(),
    Object? localization = const $CopyWithPlaceholder(),
  }) {
    return SiteConfig(
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String,
      identity: identity == const $CopyWithPlaceholder()
          ? _value.identity
          // ignore: cast_nullable_to_non_nullable
          : identity as SiteIdentity,
      localization: localization == const $CopyWithPlaceholder()
          ? _value.localization
          // ignore: cast_nullable_to_non_nullable
          : localization as SiteLocalization,
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
          requiredKeys: const ['version', 'identity', 'localization'],
        );
        final val = SiteConfig(
          version: $checkedConvert('version', (v) => v as String),
          identity: $checkedConvert('identity',
              (v) => SiteIdentity.fromJson(v as Map<String, dynamic>)),
          localization: $checkedConvert('localization',
              (v) => SiteLocalization.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SiteConfigToJson(SiteConfig instance) =>
    <String, dynamic>{
      'version': instance.version,
      'identity': instance.identity.toJson(),
      'localization': instance.localization.toJson(),
    };
