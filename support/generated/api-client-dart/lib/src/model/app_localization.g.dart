// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_localization.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppLocalizationCWProxy {
  AppLocalization defaultLocale(DefaultLocaleEnum defaultLocale);

  AppLocalization timezone(String timezone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppLocalization(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppLocalization(...).copyWith(id: 12, name: "My name")
  /// ````
  AppLocalization call({DefaultLocaleEnum defaultLocale, String timezone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAppLocalization.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAppLocalization.copyWith.fieldName(...)`
class _$AppLocalizationCWProxyImpl implements _$AppLocalizationCWProxy {
  const _$AppLocalizationCWProxyImpl(this._value);

  final AppLocalization _value;

  @override
  AppLocalization defaultLocale(DefaultLocaleEnum defaultLocale) =>
      this(defaultLocale: defaultLocale);

  @override
  AppLocalization timezone(String timezone) => this(timezone: timezone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AppLocalization(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AppLocalization(...).copyWith(id: 12, name: "My name")
  /// ````
  AppLocalization call({
    Object? defaultLocale = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
  }) {
    return AppLocalization(
      defaultLocale: defaultLocale == const $CopyWithPlaceholder()
          ? _value.defaultLocale
          // ignore: cast_nullable_to_non_nullable
          : defaultLocale as DefaultLocaleEnum,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
    );
  }
}

extension $AppLocalizationCopyWith on AppLocalization {
  /// Returns a callable class that can be used as follows: `instanceOfAppLocalization.copyWith(...)` or like so:`instanceOfAppLocalization.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppLocalizationCWProxy get copyWith => _$AppLocalizationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppLocalization _$AppLocalizationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppLocalization', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['default_locale', 'timezone']);
      final val = AppLocalization(
        defaultLocale: $checkedConvert(
          'default_locale',
          (v) => $enumDecode(_$DefaultLocaleEnumEnumMap, v),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'defaultLocale': 'default_locale'});

Map<String, dynamic> _$AppLocalizationToJson(AppLocalization instance) =>
    <String, dynamic>{
      'default_locale': _$DefaultLocaleEnumEnumMap[instance.defaultLocale]!,
      'timezone': instance.timezone,
    };

const _$DefaultLocaleEnumEnumMap = {
  DefaultLocaleEnum.sw: 'sw',
  DefaultLocaleEnum.en: 'en',
};
