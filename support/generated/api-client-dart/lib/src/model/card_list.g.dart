// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardListCWProxy {
  CardList results(List<Card> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CardList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CardList(...).copyWith(id: 12, name: "My name")
  /// ````
  CardList call({List<Card> results});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCardList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCardList.copyWith.fieldName(...)`
class _$CardListCWProxyImpl implements _$CardListCWProxy {
  const _$CardListCWProxyImpl(this._value);

  final CardList _value;

  @override
  CardList results(List<Card> results) => this(results: results);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CardList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CardList(...).copyWith(id: 12, name: "My name")
  /// ````
  CardList call({Object? results = const $CopyWithPlaceholder()}) {
    return CardList(
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
    );
  }
}

extension $CardListCopyWith on CardList {
  /// Returns a callable class that can be used as follows: `instanceOfCardList.copyWith(...)` or like so:`instanceOfCardList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardListCWProxy get copyWith => _$CardListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardList _$CardListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CardList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['results']);
      final val = CardList(
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CardListToJson(CardList instance) => <String, dynamic>{
  'results': instance.results.map((e) => e.toJson()).toList(),
};
