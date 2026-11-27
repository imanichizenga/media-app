// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schemes.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SchemesCWProxy {
  Schemes light(String light);

  Schemes dark(String dark);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Schemes(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Schemes(...).copyWith(id: 12, name: "My name")
  /// ````
  Schemes call({String light, String dark});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSchemes.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSchemes.copyWith.fieldName(...)`
class _$SchemesCWProxyImpl implements _$SchemesCWProxy {
  const _$SchemesCWProxyImpl(this._value);

  final Schemes _value;

  @override
  Schemes light(String light) => this(light: light);

  @override
  Schemes dark(String dark) => this(dark: dark);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Schemes(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Schemes(...).copyWith(id: 12, name: "My name")
  /// ````
  Schemes call({
    Object? light = const $CopyWithPlaceholder(),
    Object? dark = const $CopyWithPlaceholder(),
  }) {
    return Schemes(
      light: light == const $CopyWithPlaceholder()
          ? _value.light
          // ignore: cast_nullable_to_non_nullable
          : light as String,
      dark: dark == const $CopyWithPlaceholder()
          ? _value.dark
          // ignore: cast_nullable_to_non_nullable
          : dark as String,
    );
  }
}

extension $SchemesCopyWith on Schemes {
  /// Returns a callable class that can be used as follows: `instanceOfSchemes.copyWith(...)` or like so:`instanceOfSchemes.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SchemesCWProxy get copyWith => _$SchemesCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Schemes _$SchemesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Schemes', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['light', 'dark']);
      final val = Schemes(
        light: $checkedConvert('light', (v) => v as String),
        dark: $checkedConvert('dark', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SchemesToJson(Schemes instance) => <String, dynamic>{
  'light': instance.light,
  'dark': instance.dark,
};
