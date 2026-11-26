// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_maintenance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppMaintenanceCWProxy {
  AppMaintenance on_(bool on_);

  AppMaintenance sw(String sw);

  AppMaintenance en(String en);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppMaintenance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppMaintenance(...).copyWith(id: 12, name: "My name")
  /// ````
  AppMaintenance call({
    bool on_,
    String sw,
    String en,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppMaintenance.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppMaintenance.copyWith.fieldName(...)`
class _$AppMaintenanceCWProxyImpl implements _$AppMaintenanceCWProxy {
  const _$AppMaintenanceCWProxyImpl(this._value);

  final AppMaintenance _value;

  @override
  AppMaintenance on_(bool on_) => this(on_: on_);

  @override
  AppMaintenance sw(String sw) => this(sw: sw);

  @override
  AppMaintenance en(String en) => this(en: en);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppMaintenance(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppMaintenance(...).copyWith(id: 12, name: "My name")
  /// ````
  AppMaintenance call({
    Object? on_ = const $CopyWithPlaceholder(),
    Object? sw = const $CopyWithPlaceholder(),
    Object? en = const $CopyWithPlaceholder(),
  }) {
    return AppMaintenance(
      on_: on_ == const $CopyWithPlaceholder()
          ? _value.on_
          // ignore: cast_nullable_to_non_nullable
          : on_ as bool,
      sw: sw == const $CopyWithPlaceholder()
          ? _value.sw
          // ignore: cast_nullable_to_non_nullable
          : sw as String,
      en: en == const $CopyWithPlaceholder()
          ? _value.en
          // ignore: cast_nullable_to_non_nullable
          : en as String,
    );
  }
}

extension $AppMaintenanceCopyWith on AppMaintenance {
  /// Returns a callable class that can be used as follows: `instanceOfAppMaintenance.copyWith(...)` or like so:`instanceOfAppMaintenance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppMaintenanceCWProxy get copyWith => _$AppMaintenanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMaintenance _$AppMaintenanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AppMaintenance',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['on', 'sw', 'en'],
        );
        final val = AppMaintenance(
          on_: $checkedConvert('on', (v) => v as bool),
          sw: $checkedConvert('sw', (v) => v as String),
          en: $checkedConvert('en', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'on_': 'on'},
    );

Map<String, dynamic> _$AppMaintenanceToJson(AppMaintenance instance) =>
    <String, dynamic>{
      'on': instance.on_,
      'sw': instance.sw,
      'en': instance.en,
    };
