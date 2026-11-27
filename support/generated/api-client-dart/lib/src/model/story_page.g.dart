// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StoryPageCWProxy {
  StoryPage nextCursor(String? nextCursor);

  StoryPage results(List<Card> results);

  StoryPage story(PublicStory story);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPage(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPage call({String? nextCursor, List<Card> results, PublicStory story});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfStoryPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfStoryPage.copyWith.fieldName(...)`
class _$StoryPageCWProxyImpl implements _$StoryPageCWProxy {
  const _$StoryPageCWProxyImpl(this._value);

  final StoryPage _value;

  @override
  StoryPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  StoryPage results(List<Card> results) => this(results: results);

  @override
  StoryPage story(PublicStory story) => this(story: story);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `StoryPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// StoryPage(...).copyWith(id: 12, name: "My name")
  /// ````
  StoryPage call({
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? story = const $CopyWithPlaceholder(),
  }) {
    return StoryPage(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
      story: story == const $CopyWithPlaceholder()
          ? _value.story
          // ignore: cast_nullable_to_non_nullable
          : story as PublicStory,
    );
  }
}

extension $StoryPageCopyWith on StoryPage {
  /// Returns a callable class that can be used as follows: `instanceOfStoryPage.copyWith(...)` or like so:`instanceOfStoryPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StoryPageCWProxy get copyWith => _$StoryPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryPage _$StoryPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StoryPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['next_cursor', 'results', 'story']);
      final val = StoryPage(
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map((e) => Card.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        story: $checkedConvert(
          'story',
          (v) => PublicStory.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$StoryPageToJson(StoryPage instance) => <String, dynamic>{
  'next_cursor': instance.nextCursor,
  'results': instance.results.map((e) => e.toJson()).toList(),
  'story': instance.story.toJson(),
};
