// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchCWProxy {
  Search available(bool available);

  Search query(String query);

  Search total(int total);

  Search totalIsExact(bool totalIsExact);

  Search engine(EngineEnum engine);

  Search nextCursor(String? nextCursor);

  Search results(List<SearchHit> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Search(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Search(...).copyWith(id: 12, name: "My name")
  /// ````
  Search call({
    bool available,
    String query,
    int total,
    bool totalIsExact,
    EngineEnum engine,
    String? nextCursor,
    List<SearchHit> results,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearch.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearch.copyWith.fieldName(...)`
class _$SearchCWProxyImpl implements _$SearchCWProxy {
  const _$SearchCWProxyImpl(this._value);

  final Search _value;

  @override
  Search available(bool available) => this(available: available);

  @override
  Search query(String query) => this(query: query);

  @override
  Search total(int total) => this(total: total);

  @override
  Search totalIsExact(bool totalIsExact) => this(totalIsExact: totalIsExact);

  @override
  Search engine(EngineEnum engine) => this(engine: engine);

  @override
  Search nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  Search results(List<SearchHit> results) => this(results: results);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Search(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Search(...).copyWith(id: 12, name: "My name")
  /// ````
  Search call({
    Object? available = const $CopyWithPlaceholder(),
    Object? query = const $CopyWithPlaceholder(),
    Object? total = const $CopyWithPlaceholder(),
    Object? totalIsExact = const $CopyWithPlaceholder(),
    Object? engine = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
  }) {
    return Search(
      available: available == const $CopyWithPlaceholder()
          ? _value.available
          // ignore: cast_nullable_to_non_nullable
          : available as bool,
      query: query == const $CopyWithPlaceholder()
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      total: total == const $CopyWithPlaceholder()
          ? _value.total
          // ignore: cast_nullable_to_non_nullable
          : total as int,
      totalIsExact: totalIsExact == const $CopyWithPlaceholder()
          ? _value.totalIsExact
          // ignore: cast_nullable_to_non_nullable
          : totalIsExact as bool,
      engine: engine == const $CopyWithPlaceholder()
          ? _value.engine
          // ignore: cast_nullable_to_non_nullable
          : engine as EngineEnum,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<SearchHit>,
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
      requiredKeys: const [
        'available',
        'query',
        'total',
        'total_is_exact',
        'engine',
        'next_cursor',
        'results',
      ],
    );
    final val = Search(
      available: $checkedConvert('available', (v) => v as bool),
      query: $checkedConvert('query', (v) => v as String),
      total: $checkedConvert('total', (v) => (v as num).toInt()),
      totalIsExact: $checkedConvert('total_is_exact', (v) => v as bool),
      engine: $checkedConvert(
        'engine',
        (v) => $enumDecode(_$EngineEnumEnumMap, v),
      ),
      nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      results: $checkedConvert(
        'results',
        (v) => (v as List<dynamic>)
            .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'totalIsExact': 'total_is_exact',
    'nextCursor': 'next_cursor',
  },
);

Map<String, dynamic> _$SearchToJson(Search instance) => <String, dynamic>{
  'available': instance.available,
  'query': instance.query,
  'total': instance.total,
  'total_is_exact': instance.totalIsExact,
  'engine': _$EngineEnumEnumMap[instance.engine]!,
  'next_cursor': instance.nextCursor,
  'results': instance.results.map((e) => e.toJson()).toList(),
};

const _$EngineEnumEnumMap = {
  EngineEnum.opensearch: 'opensearch',
  EngineEnum.fallback: 'fallback',
};
