// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_translation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CategoryTranslationCWProxy {
  CategoryTranslation locale(String locale);

  CategoryTranslation path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CategoryTranslation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CategoryTranslation(...).copyWith(id: 12, name: "My name")
  /// ````
  CategoryTranslation call({
    String locale,
    String path,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCategoryTranslation.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCategoryTranslation.copyWith.fieldName(...)`
class _$CategoryTranslationCWProxyImpl implements _$CategoryTranslationCWProxy {
  const _$CategoryTranslationCWProxyImpl(this._value);

  final CategoryTranslation _value;

  @override
  CategoryTranslation locale(String locale) => this(locale: locale);

  @override
  CategoryTranslation path(String path) => this(path: path);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CategoryTranslation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CategoryTranslation(...).copyWith(id: 12, name: "My name")
  /// ````
  CategoryTranslation call({
    Object? locale = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return CategoryTranslation(
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

extension $CategoryTranslationCopyWith on CategoryTranslation {
  /// Returns a callable class that can be used as follows: `instanceOfCategoryTranslation.copyWith(...)` or like so:`instanceOfCategoryTranslation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CategoryTranslationCWProxy get copyWith =>
      _$CategoryTranslationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryTranslation _$CategoryTranslationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CategoryTranslation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['locale', 'path'],
        );
        final val = CategoryTranslation(
          locale: $checkedConvert('locale', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CategoryTranslationToJson(
        CategoryTranslation instance) =>
    <String, dynamic>{
      'locale': instance.locale,
      'path': instance.path,
    };
