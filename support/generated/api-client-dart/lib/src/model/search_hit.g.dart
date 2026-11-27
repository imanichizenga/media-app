// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_hit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SearchHitCWProxy {
  SearchHit card(Card card);

  SearchHit snippet(List<Segment> snippet);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchHit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchHit(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchHit call({Card card, List<Segment> snippet});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSearchHit.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSearchHit.copyWith.fieldName(...)`
class _$SearchHitCWProxyImpl implements _$SearchHitCWProxy {
  const _$SearchHitCWProxyImpl(this._value);

  final SearchHit _value;

  @override
  SearchHit card(Card card) => this(card: card);

  @override
  SearchHit snippet(List<Segment> snippet) => this(snippet: snippet);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SearchHit(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SearchHit(...).copyWith(id: 12, name: "My name")
  /// ````
  SearchHit call({
    Object? card = const $CopyWithPlaceholder(),
    Object? snippet = const $CopyWithPlaceholder(),
  }) {
    return SearchHit(
      card: card == const $CopyWithPlaceholder()
          ? _value.card
          // ignore: cast_nullable_to_non_nullable
          : card as Card,
      snippet: snippet == const $CopyWithPlaceholder()
          ? _value.snippet
          // ignore: cast_nullable_to_non_nullable
          : snippet as List<Segment>,
    );
  }
}

extension $SearchHitCopyWith on SearchHit {
  /// Returns a callable class that can be used as follows: `instanceOfSearchHit.copyWith(...)` or like so:`instanceOfSearchHit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SearchHitCWProxy get copyWith => _$SearchHitCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchHit _$SearchHitFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SearchHit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['card', 'snippet']);
      final val = SearchHit(
        card: $checkedConvert(
          'card',
          (v) => Card.fromJson(v as Map<String, dynamic>),
        ),
        snippet: $checkedConvert(
          'snippet',
          (v) => (v as List<dynamic>)
              .map((e) => Segment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SearchHitToJson(SearchHit instance) => <String, dynamic>{
  'card': instance.card.toJson(),
  'snippet': instance.snippet.map((e) => e.toJson()).toList(),
};
