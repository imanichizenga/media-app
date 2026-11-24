// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_theme_tokens.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteThemeTokensCWProxy {
  SiteThemeTokens light(Map<String, String> light);

  SiteThemeTokens dark(Map<String, String> dark);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteThemeTokens(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteThemeTokens(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteThemeTokens call({
    Map<String, String> light,
    Map<String, String> dark,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteThemeTokens.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteThemeTokens.copyWith.fieldName(...)`
class _$SiteThemeTokensCWProxyImpl implements _$SiteThemeTokensCWProxy {
  const _$SiteThemeTokensCWProxyImpl(this._value);

  final SiteThemeTokens _value;

  @override
  SiteThemeTokens light(Map<String, String> light) => this(light: light);

  @override
  SiteThemeTokens dark(Map<String, String> dark) => this(dark: dark);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteThemeTokens(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteThemeTokens(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteThemeTokens call({
    Object? light = const $CopyWithPlaceholder(),
    Object? dark = const $CopyWithPlaceholder(),
  }) {
    return SiteThemeTokens(
      light: light == const $CopyWithPlaceholder()
          ? _value.light
          // ignore: cast_nullable_to_non_nullable
          : light as Map<String, String>,
      dark: dark == const $CopyWithPlaceholder()
          ? _value.dark
          // ignore: cast_nullable_to_non_nullable
          : dark as Map<String, String>,
    );
  }
}

extension $SiteThemeTokensCopyWith on SiteThemeTokens {
  /// Returns a callable class that can be used as follows: `instanceOfSiteThemeTokens.copyWith(...)` or like so:`instanceOfSiteThemeTokens.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteThemeTokensCWProxy get copyWith => _$SiteThemeTokensCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteThemeTokens _$SiteThemeTokensFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SiteThemeTokens',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['light', 'dark'],
        );
        final val = SiteThemeTokens(
          light: $checkedConvert(
              'light', (v) => Map<String, String>.from(v as Map)),
          dark: $checkedConvert(
              'dark', (v) => Map<String, String>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SiteThemeTokensToJson(SiteThemeTokens instance) =>
    <String, dynamic>{
      'light': instance.light,
      'dark': instance.dark,
    };
