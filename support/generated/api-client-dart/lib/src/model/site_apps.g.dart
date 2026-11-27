// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_apps.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteAppsCWProxy {
  SiteApps android(String android);

  SiteApps ios(String ios);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteApps(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteApps(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteApps call({String android, String ios});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteApps.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteApps.copyWith.fieldName(...)`
class _$SiteAppsCWProxyImpl implements _$SiteAppsCWProxy {
  const _$SiteAppsCWProxyImpl(this._value);

  final SiteApps _value;

  @override
  SiteApps android(String android) => this(android: android);

  @override
  SiteApps ios(String ios) => this(ios: ios);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteApps(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteApps(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteApps call({
    Object? android = const $CopyWithPlaceholder(),
    Object? ios = const $CopyWithPlaceholder(),
  }) {
    return SiteApps(
      android: android == const $CopyWithPlaceholder()
          ? _value.android
          // ignore: cast_nullable_to_non_nullable
          : android as String,
      ios: ios == const $CopyWithPlaceholder()
          ? _value.ios
          // ignore: cast_nullable_to_non_nullable
          : ios as String,
    );
  }
}

extension $SiteAppsCopyWith on SiteApps {
  /// Returns a callable class that can be used as follows: `instanceOfSiteApps.copyWith(...)` or like so:`instanceOfSiteApps.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteAppsCWProxy get copyWith => _$SiteAppsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteApps _$SiteAppsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteApps', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['android', 'ios']);
      final val = SiteApps(
        android: $checkedConvert('android', (v) => v as String),
        ios: $checkedConvert('ios', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SiteAppsToJson(SiteApps instance) => <String, dynamic>{
  'android': instance.android,
  'ios': instance.ios,
};
