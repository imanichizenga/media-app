// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_localization.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteLocalizationCWProxy {
  SiteLocalization defaultLocale(DefaultLocaleEnum defaultLocale);

  SiteLocalization timezone(String timezone);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteLocalization(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteLocalization(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteLocalization call({DefaultLocaleEnum defaultLocale, String timezone});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteLocalization.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteLocalization.copyWith.fieldName(...)`
class _$SiteLocalizationCWProxyImpl implements _$SiteLocalizationCWProxy {
  const _$SiteLocalizationCWProxyImpl(this._value);

  final SiteLocalization _value;

  @override
  SiteLocalization defaultLocale(DefaultLocaleEnum defaultLocale) =>
      this(defaultLocale: defaultLocale);

  @override
  SiteLocalization timezone(String timezone) => this(timezone: timezone);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteLocalization(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteLocalization(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteLocalization call({
    Object? defaultLocale = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
  }) {
    return SiteLocalization(
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

extension $SiteLocalizationCopyWith on SiteLocalization {
  /// Returns a callable class that can be used as follows: `instanceOfSiteLocalization.copyWith(...)` or like so:`instanceOfSiteLocalization.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteLocalizationCWProxy get copyWith => _$SiteLocalizationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteLocalization _$SiteLocalizationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteLocalization', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['default_locale', 'timezone']);
      final val = SiteLocalization(
        defaultLocale: $checkedConvert(
          'default_locale',
          (v) => $enumDecode(_$DefaultLocaleEnumEnumMap, v),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'defaultLocale': 'default_locale'});

Map<String, dynamic> _$SiteLocalizationToJson(SiteLocalization instance) =>
    <String, dynamic>{
      'default_locale': _$DefaultLocaleEnumEnumMap[instance.defaultLocale]!,
      'timezone': instance.timezone,
    };

const _$DefaultLocaleEnumEnumMap = {
  DefaultLocaleEnum.sw: 'sw',
  DefaultLocaleEnum.en: 'en',
};
