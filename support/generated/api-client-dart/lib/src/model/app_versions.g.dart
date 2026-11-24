// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_versions.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppVersionsCWProxy {
  AppVersions ios(AppPlatformVersions ios);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppVersions(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppVersions(...).copyWith(id: 12, name: "My name")
  /// ````
  AppVersions call({
    AppPlatformVersions ios,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppVersions.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppVersions.copyWith.fieldName(...)`
class _$AppVersionsCWProxyImpl implements _$AppVersionsCWProxy {
  const _$AppVersionsCWProxyImpl(this._value);

  final AppVersions _value;

  @override
  AppVersions ios(AppPlatformVersions ios) => this(ios: ios);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppVersions(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppVersions(...).copyWith(id: 12, name: "My name")
  /// ````
  AppVersions call({
    Object? ios = const $CopyWithPlaceholder(),
  }) {
    return AppVersions(
      ios: ios == const $CopyWithPlaceholder()
          ? _value.ios
          // ignore: cast_nullable_to_non_nullable
          : ios as AppPlatformVersions,
    );
  }
}

extension $AppVersionsCopyWith on AppVersions {
  /// Returns a callable class that can be used as follows: `instanceOfAppVersions.copyWith(...)` or like so:`instanceOfAppVersions.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppVersionsCWProxy get copyWith => _$AppVersionsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVersions _$AppVersionsFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AppVersions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ios'],
        );
        final val = AppVersions(
          ios: $checkedConvert('ios',
              (v) => AppPlatformVersions.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AppVersionsToJson(AppVersions instance) =>
    <String, dynamic>{
      'ios': instance.ios.toJson(),
    };
