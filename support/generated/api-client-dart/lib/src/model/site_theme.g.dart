// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_theme.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteThemeCWProxy {
  SiteTheme schemaVersion(int schemaVersion);

  SiteTheme hash(String hash);

  SiteTheme key(ThemeKeyEnum key);

  SiteTheme color(String color);

  SiteTheme darkColor(String darkColor);

  SiteTheme css(String css);

  SiteTheme themeColor(Schemes themeColor);

  SiteTheme tokens(SiteThemeTokens tokens);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteTheme(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteTheme(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteTheme call({
    int schemaVersion,
    String hash,
    ThemeKeyEnum key,
    String color,
    String darkColor,
    String css,
    Schemes themeColor,
    SiteThemeTokens tokens,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSiteTheme.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSiteTheme.copyWith.fieldName(...)`
class _$SiteThemeCWProxyImpl implements _$SiteThemeCWProxy {
  const _$SiteThemeCWProxyImpl(this._value);

  final SiteTheme _value;

  @override
  SiteTheme schemaVersion(int schemaVersion) =>
      this(schemaVersion: schemaVersion);

  @override
  SiteTheme hash(String hash) => this(hash: hash);

  @override
  SiteTheme key(ThemeKeyEnum key) => this(key: key);

  @override
  SiteTheme color(String color) => this(color: color);

  @override
  SiteTheme darkColor(String darkColor) => this(darkColor: darkColor);

  @override
  SiteTheme css(String css) => this(css: css);

  @override
  SiteTheme themeColor(Schemes themeColor) => this(themeColor: themeColor);

  @override
  SiteTheme tokens(SiteThemeTokens tokens) => this(tokens: tokens);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SiteTheme(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SiteTheme(...).copyWith(id: 12, name: "My name")
  /// ````
  SiteTheme call({
    Object? schemaVersion = const $CopyWithPlaceholder(),
    Object? hash = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? darkColor = const $CopyWithPlaceholder(),
    Object? css = const $CopyWithPlaceholder(),
    Object? themeColor = const $CopyWithPlaceholder(),
    Object? tokens = const $CopyWithPlaceholder(),
  }) {
    return SiteTheme(
      schemaVersion: schemaVersion == const $CopyWithPlaceholder()
          ? _value.schemaVersion
          // ignore: cast_nullable_to_non_nullable
          : schemaVersion as int,
      hash: hash == const $CopyWithPlaceholder()
          ? _value.hash
          // ignore: cast_nullable_to_non_nullable
          : hash as String,
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as ThemeKeyEnum,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
      darkColor: darkColor == const $CopyWithPlaceholder()
          ? _value.darkColor
          // ignore: cast_nullable_to_non_nullable
          : darkColor as String,
      css: css == const $CopyWithPlaceholder()
          ? _value.css
          // ignore: cast_nullable_to_non_nullable
          : css as String,
      themeColor: themeColor == const $CopyWithPlaceholder()
          ? _value.themeColor
          // ignore: cast_nullable_to_non_nullable
          : themeColor as Schemes,
      tokens: tokens == const $CopyWithPlaceholder()
          ? _value.tokens
          // ignore: cast_nullable_to_non_nullable
          : tokens as SiteThemeTokens,
    );
  }
}

extension $SiteThemeCopyWith on SiteTheme {
  /// Returns a callable class that can be used as follows: `instanceOfSiteTheme.copyWith(...)` or like so:`instanceOfSiteTheme.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteThemeCWProxy get copyWith => _$SiteThemeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteTheme _$SiteThemeFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SiteTheme',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'schema_version',
            'hash',
            'key',
            'color',
            'dark_color',
            'css',
            'theme_color',
            'tokens'
          ],
        );
        final val = SiteTheme(
          schemaVersion:
              $checkedConvert('schema_version', (v) => (v as num).toInt()),
          hash: $checkedConvert('hash', (v) => v as String),
          key: $checkedConvert(
              'key', (v) => $enumDecode(_$ThemeKeyEnumEnumMap, v)),
          color: $checkedConvert('color', (v) => v as String),
          darkColor: $checkedConvert('dark_color', (v) => v as String),
          css: $checkedConvert('css', (v) => v as String),
          themeColor: $checkedConvert('theme_color',
              (v) => Schemes.fromJson(v as Map<String, dynamic>)),
          tokens: $checkedConvert('tokens',
              (v) => SiteThemeTokens.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'schemaVersion': 'schema_version',
        'darkColor': 'dark_color',
        'themeColor': 'theme_color'
      },
    );

Map<String, dynamic> _$SiteThemeToJson(SiteTheme instance) => <String, dynamic>{
      'schema_version': instance.schemaVersion,
      'hash': instance.hash,
      'key': _$ThemeKeyEnumEnumMap[instance.key]!,
      'color': instance.color,
      'dark_color': instance.darkColor,
      'css': instance.css,
      'theme_color': instance.themeColor.toJson(),
      'tokens': instance.tokens.toJson(),
    };

const _$ThemeKeyEnumEnumMap = {
  ThemeKeyEnum.signature: 'signature',
  ThemeKeyEnum.bold: 'bold',
  ThemeKeyEnum.quiet: 'quiet',
};
