// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FeedPageCWProxy {
  FeedPage nextCursor(String? nextCursor);

  FeedPage results(List<Card> results);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FeedPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FeedPage(...).copyWith(id: 12, name: "My name")
  /// ````
  FeedPage call({
    String? nextCursor,
    List<Card> results,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFeedPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFeedPage.copyWith.fieldName(...)`
class _$FeedPageCWProxyImpl implements _$FeedPageCWProxy {
  const _$FeedPageCWProxyImpl(this._value);

  final FeedPage _value;

  @override
  FeedPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  FeedPage results(List<Card> results) => this(results: results);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `FeedPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// FeedPage(...).copyWith(id: 12, name: "My name")
  /// ````
  FeedPage call({
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
  }) {
    return FeedPage(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
    );
  }
}

extension $FeedPageCopyWith on FeedPage {
  /// Returns a callable class that can be used as follows: `instanceOfFeedPage.copyWith(...)` or like so:`instanceOfFeedPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FeedPageCWProxy get copyWith => _$FeedPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedPage _$FeedPageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'FeedPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['next_cursor', 'results'],
        );
        final val = FeedPage(
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => Card.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$FeedPageToJson(FeedPage instance) => <String, dynamic>{
      'next_cursor': instance.nextCursor,
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
