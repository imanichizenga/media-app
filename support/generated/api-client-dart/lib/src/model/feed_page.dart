//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'feed_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FeedPage {
  /// Returns a new [FeedPage] instance.
  FeedPage({required this.nextCursor, required this.results});

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedPage &&
          other.nextCursor == nextCursor &&
          other.results == results;

  @override
  int get hashCode =>
      (nextCursor == null ? 0 : nextCursor.hashCode) + results.hashCode;

  factory FeedPage.fromJson(Map<String, dynamic> json) =>
      _$FeedPageFromJson(json);

  Map<String, dynamic> toJson() => _$FeedPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
