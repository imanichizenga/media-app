// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'readers.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReadersCWProxy {
  Readers readers(int readers);

  Readers views(int views);

  Readers guests(int guests);

  Readers results(List<ReaderEntry> results);

  Readers nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readers(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readers(...).copyWith(id: 12, name: "My name")
  /// ````
  Readers call({
    int readers,
    int views,
    int guests,
    List<ReaderEntry> results,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReaders.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReaders.copyWith.fieldName(...)`
class _$ReadersCWProxyImpl implements _$ReadersCWProxy {
  const _$ReadersCWProxyImpl(this._value);

  final Readers _value;

  @override
  Readers readers(int readers) => this(readers: readers);

  @override
  Readers views(int views) => this(views: views);

  @override
  Readers guests(int guests) => this(guests: guests);

  @override
  Readers results(List<ReaderEntry> results) => this(results: results);

  @override
  Readers nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Readers(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Readers(...).copyWith(id: 12, name: "My name")
  /// ````
  Readers call({
    Object? readers = const $CopyWithPlaceholder(),
    Object? views = const $CopyWithPlaceholder(),
    Object? guests = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return Readers(
      readers: readers == const $CopyWithPlaceholder()
          ? _value.readers
          // ignore: cast_nullable_to_non_nullable
          : readers as int,
      views: views == const $CopyWithPlaceholder()
          ? _value.views
          // ignore: cast_nullable_to_non_nullable
          : views as int,
      guests: guests == const $CopyWithPlaceholder()
          ? _value.guests
          // ignore: cast_nullable_to_non_nullable
          : guests as int,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<ReaderEntry>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $ReadersCopyWith on Readers {
  /// Returns a callable class that can be used as follows: `instanceOfReaders.copyWith(...)` or like so:`instanceOfReaders.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReadersCWProxy get copyWith => _$ReadersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Readers _$ReadersFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Readers', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'readers',
          'views',
          'guests',
          'results',
          'next_cursor',
        ],
      );
      final val = Readers(
        readers: $checkedConvert('readers', (v) => (v as num).toInt()),
        views: $checkedConvert('views', (v) => (v as num).toInt()),
        guests: $checkedConvert('guests', (v) => (v as num).toInt()),
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map((e) => ReaderEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$ReadersToJson(Readers instance) => <String, dynamic>{
  'readers': instance.readers,
  'views': instance.views,
  'guests': instance.guests,
  'results': instance.results.map((e) => e.toJson()).toList(),
  'next_cursor': instance.nextCursor,
};
