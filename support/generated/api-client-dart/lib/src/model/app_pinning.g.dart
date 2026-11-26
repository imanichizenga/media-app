// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_pinning.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppPinningCWProxy {
  AppPinning enabled(bool enabled);

  AppPinning pins(List<String> pins);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppPinning(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppPinning(...).copyWith(id: 12, name: "My name")
  /// ````
  AppPinning call({
    bool enabled,
    List<String> pins,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppPinning.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppPinning.copyWith.fieldName(...)`
class _$AppPinningCWProxyImpl implements _$AppPinningCWProxy {
  const _$AppPinningCWProxyImpl(this._value);

  final AppPinning _value;

  @override
  AppPinning enabled(bool enabled) => this(enabled: enabled);

  @override
  AppPinning pins(List<String> pins) => this(pins: pins);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppPinning(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppPinning(...).copyWith(id: 12, name: "My name")
  /// ````
  AppPinning call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? pins = const $CopyWithPlaceholder(),
  }) {
    return AppPinning(
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      pins: pins == const $CopyWithPlaceholder()
          ? _value.pins
          // ignore: cast_nullable_to_non_nullable
          : pins as List<String>,
    );
  }
}

extension $AppPinningCopyWith on AppPinning {
  /// Returns a callable class that can be used as follows: `instanceOfAppPinning.copyWith(...)` or like so:`instanceOfAppPinning.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppPinningCWProxy get copyWith => _$AppPinningCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppPinning _$AppPinningFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AppPinning',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['enabled', 'pins'],
        );
        final val = AppPinning(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          pins: $checkedConvert('pins',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$AppPinningToJson(AppPinning instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'pins': instance.pins,
    };
