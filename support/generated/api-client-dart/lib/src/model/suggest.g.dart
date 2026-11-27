// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggest.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SuggestCWProxy {
  Suggest query(String query);

  Suggest results(List<Suggestion> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggest(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggest call({String query, List<Suggestion> results});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSuggest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSuggest.copyWith.fieldName(...)`
class _$SuggestCWProxyImpl implements _$SuggestCWProxy {
  const _$SuggestCWProxyImpl(this._value);

  final Suggest _value;

  @override
  Suggest query(String query) => this(query: query);

  @override
  Suggest results(List<Suggestion> results) => this(results: results);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Suggest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Suggest(...).copyWith(id: 12, name: "My name")
  /// ````
  Suggest call({
    Object? query = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
  }) {
    return Suggest(
      query: query == const $CopyWithPlaceholder()
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Suggestion>,
    );
  }
}

extension $SuggestCopyWith on Suggest {
  /// Returns a callable class that can be used as follows: `instanceOfSuggest.copyWith(...)` or like so:`instanceOfSuggest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SuggestCWProxy get copyWith => _$SuggestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Suggest _$SuggestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Suggest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['query', 'results']);
      final val = Suggest(
        query: $checkedConvert('query', (v) => v as String),
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SuggestToJson(Suggest instance) => <String, dynamic>{
  'query': instance.query,
  'results': instance.results.map((e) => e.toJson()).toList(),
};
