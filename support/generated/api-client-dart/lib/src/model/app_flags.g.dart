// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_flags.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppFlagsCWProxy {
  AppFlags shorts(bool shorts);

  AppFlags youtube(bool youtube);

  AppFlags offlineSaving(bool offlineSaving);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppFlags(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppFlags(...).copyWith(id: 12, name: "My name")
  /// ````
  AppFlags call({
    bool shorts,
    bool youtube,
    bool offlineSaving,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppFlags.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppFlags.copyWith.fieldName(...)`
class _$AppFlagsCWProxyImpl implements _$AppFlagsCWProxy {
  const _$AppFlagsCWProxyImpl(this._value);

  final AppFlags _value;

  @override
  AppFlags shorts(bool shorts) => this(shorts: shorts);

  @override
  AppFlags youtube(bool youtube) => this(youtube: youtube);

  @override
  AppFlags offlineSaving(bool offlineSaving) =>
      this(offlineSaving: offlineSaving);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppFlags(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppFlags(...).copyWith(id: 12, name: "My name")
  /// ````
  AppFlags call({
    Object? shorts = const $CopyWithPlaceholder(),
    Object? youtube = const $CopyWithPlaceholder(),
    Object? offlineSaving = const $CopyWithPlaceholder(),
  }) {
    return AppFlags(
      shorts: shorts == const $CopyWithPlaceholder()
          ? _value.shorts
          // ignore: cast_nullable_to_non_nullable
          : shorts as bool,
      youtube: youtube == const $CopyWithPlaceholder()
          ? _value.youtube
          // ignore: cast_nullable_to_non_nullable
          : youtube as bool,
      offlineSaving: offlineSaving == const $CopyWithPlaceholder()
          ? _value.offlineSaving
          // ignore: cast_nullable_to_non_nullable
          : offlineSaving as bool,
    );
  }
}

extension $AppFlagsCopyWith on AppFlags {
  /// Returns a callable class that can be used as follows: `instanceOfAppFlags.copyWith(...)` or like so:`instanceOfAppFlags.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppFlagsCWProxy get copyWith => _$AppFlagsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppFlags _$AppFlagsFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AppFlags',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['shorts', 'youtube', 'offline_saving'],
        );
        final val = AppFlags(
          shorts: $checkedConvert('shorts', (v) => v as bool),
          youtube: $checkedConvert('youtube', (v) => v as bool),
          offlineSaving: $checkedConvert('offline_saving', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'offlineSaving': 'offline_saving'},
    );

Map<String, dynamic> _$AppFlagsToJson(AppFlags instance) => <String, dynamic>{
      'shorts': instance.shorts,
      'youtube': instance.youtube,
      'offline_saving': instance.offlineSaving,
    };
