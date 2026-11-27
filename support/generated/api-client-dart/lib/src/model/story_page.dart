//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_story.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'story_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StoryPage {
  /// Returns a new [StoryPage] instance.
  StoryPage({
    required this.nextCursor,

    required this.results,

    required this.story,
  });

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @JsonKey(name: r'story', required: true, includeIfNull: false)
  final PublicStory story;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryPage &&
          other.nextCursor == nextCursor &&
          other.results == results &&
          other.story == story;

  @override
  int get hashCode =>
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      results.hashCode +
      story.hashCode;

  factory StoryPage.fromJson(Map<String, dynamic> json) =>
      _$StoryPageFromJson(json);

  Map<String, dynamic> toJson() => _$StoryPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
