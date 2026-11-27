// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggestion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuggestionCWProxy {
  Suggestion headline(String headline);

  Suggestion path(String path);

  Suggestion type(String type);

  Suggestion category(String category);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggestion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggestion(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggestion call({String headline, String path, String type, String category});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSuggestion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSuggestion.copyWith.fieldName(...)`
class _$SuggestionCWProxyImpl implements _$SuggestionCWProxy {
  const _$SuggestionCWProxyImpl(this._value);

  final Suggestion _value;

  @override
  Suggestion headline(String headline) => this(headline: headline);

  @override
  Suggestion path(String path) => this(path: path);

  @override
  Suggestion type(String type) => this(type: type);

  @override
  Suggestion category(String category) => this(category: category);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggestion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggestion(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggestion call({
    Object? headline = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
  }) {
    return Suggestion(
      headline: headline == const $CopyWithPlaceholder()
          ? _value.headline
          // ignore: cast_nullable_to_non_nullable
          : headline as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String,
    );
  }
}

extension $SuggestionCopyWith on Suggestion {
  /// Returns a callable class that can be used as follows: `instanceOfSuggestion.copyWith(...)` or like so:`instanceOfSuggestion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuggestionCWProxy get copyWith => _$SuggestionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suggestion _$SuggestionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Suggestion', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['headline', 'path', 'type', 'category'],
      );
      final val = Suggestion(
        headline: $checkedConvert('headline', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        category: $checkedConvert('category', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SuggestionToJson(Suggestion instance) =>
    <String, dynamic>{
      'headline': instance.headline,
      'path': instance.path,
      'type': instance.type,
      'category': instance.category,
    };
