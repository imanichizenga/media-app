// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'related.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelatedCWProxy {
  Related results(List<Card> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Related(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Related(...).copyWith(id: 12, name: "My name")
  /// ````
  Related call({
    List<Card> results,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRelated.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRelated.copyWith.fieldName(...)`
class _$RelatedCWProxyImpl implements _$RelatedCWProxy {
  const _$RelatedCWProxyImpl(this._value);

  final Related _value;

  @override
  Related results(List<Card> results) => this(results: results);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Related(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Related(...).copyWith(id: 12, name: "My name")
  /// ````
  Related call({
    Object? results = const $CopyWithPlaceholder(),
  }) {
    return Related(
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
    );
  }
}

extension $RelatedCopyWith on Related {
  /// Returns a callable class that can be used as follows: `instanceOfRelated.copyWith(...)` or like so:`instanceOfRelated.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelatedCWProxy get copyWith => _$RelatedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Related _$RelatedFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Related',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['results'],
        );
        final val = Related(
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => Card.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$RelatedToJson(Related instance) => <String, dynamic>{
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
