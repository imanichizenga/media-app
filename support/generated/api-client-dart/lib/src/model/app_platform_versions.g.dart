// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_platform_versions.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppPlatformVersionsCWProxy {
  AppPlatformVersions minimum(String minimum);

  AppPlatformVersions recommended(String recommended);

  AppPlatformVersions store(String store);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppPlatformVersions(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppPlatformVersions(...).copyWith(id: 12, name: "My name")
  /// ````
  AppPlatformVersions call({
    String minimum,
    String recommended,
    String store,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppPlatformVersions.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppPlatformVersions.copyWith.fieldName(...)`
class _$AppPlatformVersionsCWProxyImpl implements _$AppPlatformVersionsCWProxy {
  const _$AppPlatformVersionsCWProxyImpl(this._value);

  final AppPlatformVersions _value;

  @override
  AppPlatformVersions minimum(String minimum) => this(minimum: minimum);

  @override
  AppPlatformVersions recommended(String recommended) =>
      this(recommended: recommended);

  @override
  AppPlatformVersions store(String store) => this(store: store);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppPlatformVersions(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppPlatformVersions(...).copyWith(id: 12, name: "My name")
  /// ````
  AppPlatformVersions call({
    Object? minimum = const $CopyWithPlaceholder(),
    Object? recommended = const $CopyWithPlaceholder(),
    Object? store = const $CopyWithPlaceholder(),
  }) {
    return AppPlatformVersions(
      minimum: minimum == const $CopyWithPlaceholder()
          ? _value.minimum
          // ignore: cast_nullable_to_non_nullable
          : minimum as String,
      recommended: recommended == const $CopyWithPlaceholder()
          ? _value.recommended
          // ignore: cast_nullable_to_non_nullable
          : recommended as String,
      store: store == const $CopyWithPlaceholder()
          ? _value.store
          // ignore: cast_nullable_to_non_nullable
          : store as String,
    );
  }
}

extension $AppPlatformVersionsCopyWith on AppPlatformVersions {
  /// Returns a callable class that can be used as follows: `instanceOfAppPlatformVersions.copyWith(...)` or like so:`instanceOfAppPlatformVersions.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppPlatformVersionsCWProxy get copyWith =>
      _$AppPlatformVersionsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppPlatformVersions _$AppPlatformVersionsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppPlatformVersions',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['minimum', 'recommended', 'store'],
        );
        final val = AppPlatformVersions(
          minimum: $checkedConvert('minimum', (v) => v as String),
          recommended: $checkedConvert('recommended', (v) => v as String),
          store: $checkedConvert('store', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$AppPlatformVersionsToJson(
        AppPlatformVersions instance) =>
    <String, dynamic>{
      'minimum': instance.minimum,
      'recommended': instance.recommended,
      'store': instance.store,
    };
