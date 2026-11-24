// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchCWProxy {
  Search nextCursor(String? nextCursor);

  Search results(List<Card> results);

  Search available(bool available);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Search(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Search(...).copyWith(id: 12, name: "My name")
  /// ````
  Search call({
    String? nextCursor,
    List<Card> results,
    bool available,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearch.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearch.copyWith.fieldName(...)`
class _$SearchCWProxyImpl implements _$SearchCWProxy {
  const _$SearchCWProxyImpl(this._value);

  final Search _value;

  @override
  Search nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  Search results(List<Card> results) => this(results: results);

  @override
  Search available(bool available) => this(available: available);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Search(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Search(...).copyWith(id: 12, name: "My name")
  /// ````
  Search call({
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? available = const $CopyWithPlaceholder(),
  }) {
    return Search(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
      available: available == const $CopyWithPlaceholder()
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
    );
  }
}

extension $SearchCopyWith on Search {
  /// Returns a callable class that can be used as follows: `instanceOfSearch.copyWith(...)` or like so:`instanceOfSearch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchCWProxy get copyWith => _$SearchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Search _$SearchFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Search',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['next_cursor', 'results', 'available'],
        );
        final val = Search(
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => Card.fromJson(e as Map<String, dynamic>))
                  .toList()),
          available: $checkedConvert('available', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$SearchToJson(Search instance) => <String, dynamic>{
      'next_cursor': instance.nextCursor,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'available': instance.available,
    };
