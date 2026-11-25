// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_translation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageTranslationCWProxy {
  PageTranslation locale(String locale);

  PageTranslation path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageTranslation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageTranslation(...).copyWith(id: 12, name: "My name")
  /// ````
  PageTranslation call({
    String locale,
    String path,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPageTranslation.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPageTranslation.copyWith.fieldName(...)`
class _$PageTranslationCWProxyImpl implements _$PageTranslationCWProxy {
  const _$PageTranslationCWProxyImpl(this._value);

  final PageTranslation _value;

  @override
  PageTranslation locale(String locale) => this(locale: locale);

  @override
  PageTranslation path(String path) => this(path: path);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PageTranslation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PageTranslation(...).copyWith(id: 12, name: "My name")
  /// ````
  PageTranslation call({
    Object? locale = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return PageTranslation(
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

extension $PageTranslationCopyWith on PageTranslation {
  /// Returns a callable class that can be used as follows: `instanceOfPageTranslation.copyWith(...)` or like so:`instanceOfPageTranslation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageTranslationCWProxy get copyWith => _$PageTranslationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageTranslation _$PageTranslationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PageTranslation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['locale', 'path'],
        );
        final val = PageTranslation(
          locale: $checkedConvert('locale', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PageTranslationToJson(PageTranslation instance) =>
    <String, dynamic>{
      'locale': instance.locale,
      'path': instance.path,
    };
