// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TagPageCWProxy {
  TagPage nextCursor(String? nextCursor);

  TagPage results(List<Card> results);

  TagPage tag(PublicLabel tag);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TagPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TagPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TagPage call({
    String? nextCursor,
    List<Card> results,
    PublicLabel tag,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTagPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTagPage.copyWith.fieldName(...)`
class _$TagPageCWProxyImpl implements _$TagPageCWProxy {
  const _$TagPageCWProxyImpl(this._value);

  final TagPage _value;

  @override
  TagPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  TagPage results(List<Card> results) => this(results: results);

  @override
  TagPage tag(PublicLabel tag) => this(tag: tag);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TagPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TagPage(...).copyWith(id: 12, name: "My name")
  /// ````
  TagPage call({
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? tag = const $CopyWithPlaceholder(),
  }) {
    return TagPage(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
      tag: tag == const $CopyWithPlaceholder()
          ? _value.tag
          // ignore: cast_nullable_to_non_nullable
          : tag as PublicLabel,
    );
  }
}

extension $TagPageCopyWith on TagPage {
  /// Returns a callable class that can be used as follows: `instanceOfTagPage.copyWith(...)` or like so:`instanceOfTagPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TagPageCWProxy get copyWith => _$TagPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagPage _$TagPageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TagPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['next_cursor', 'results', 'tag'],
        );
        final val = TagPage(
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
          results: $checkedConvert(
              'results',
              (v) => (v as List<dynamic>)
                  .map((e) => Card.fromJson(e as Map<String, dynamic>))
                  .toList()),
          tag: $checkedConvert(
              'tag', (v) => PublicLabel.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$TagPageToJson(TagPage instance) => <String, dynamic>{
      'next_cursor': instance.nextCursor,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'tag': instance.tag.toJson(),
    };
