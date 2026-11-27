// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sitemap_translation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SitemapTranslationCWProxy {
  SitemapTranslation locale(String locale);

  SitemapTranslation path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapTranslation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapTranslation(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapTranslation call({String locale, String path});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSitemapTranslation.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSitemapTranslation.copyWith.fieldName(...)`
class _$SitemapTranslationCWProxyImpl implements _$SitemapTranslationCWProxy {
  const _$SitemapTranslationCWProxyImpl(this._value);

  final SitemapTranslation _value;

  @override
  SitemapTranslation locale(String locale) => this(locale: locale);

  @override
  SitemapTranslation path(String path) => this(path: path);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapTranslation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapTranslation(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapTranslation call({
    Object? locale = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return SitemapTranslation(
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
    );
  }
}

extension $SitemapTranslationCopyWith on SitemapTranslation {
  /// Returns a callable class that can be used as follows: `instanceOfSitemapTranslation.copyWith(...)` or like so:`instanceOfSitemapTranslation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SitemapTranslationCWProxy get copyWith =>
      _$SitemapTranslationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SitemapTranslation _$SitemapTranslationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SitemapTranslation', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['locale', 'path']);
      final val = SitemapTranslation(
        locale: $checkedConvert('locale', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SitemapTranslationToJson(SitemapTranslation instance) =>
    <String, dynamic>{'locale': instance.locale, 'path': instance.path};
