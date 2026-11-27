// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TranslationCWProxy {
  Translation locale(String locale);

  Translation path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Translation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Translation(...).copyWith(id: 12, name: "My name")
  /// ````
  Translation call({String locale, String path});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTranslation.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTranslation.copyWith.fieldName(...)`
class _$TranslationCWProxyImpl implements _$TranslationCWProxy {
  const _$TranslationCWProxyImpl(this._value);

  final Translation _value;

  @override
  Translation locale(String locale) => this(locale: locale);

  @override
  Translation path(String path) => this(path: path);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Translation(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Translation(...).copyWith(id: 12, name: "My name")
  /// ````
  Translation call({
    Object? locale = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return Translation(
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

extension $TranslationCopyWith on Translation {
  /// Returns a callable class that can be used as follows: `instanceOfTranslation.copyWith(...)` or like so:`instanceOfTranslation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TranslationCWProxy get copyWith => _$TranslationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Translation _$TranslationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Translation', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['locale', 'path']);
      final val = Translation(
        locale: $checkedConvert('locale', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TranslationToJson(Translation instance) =>
    <String, dynamic>{'locale': instance.locale, 'path': instance.path};
