//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/card.dart';
import 'package:news_api_client/src/model/public_label.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tag_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TagPage {
  /// Returns a new [TagPage] instance.
  TagPage({required this.nextCursor, required this.results, required this.tag});

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @JsonKey(name: r'tag', required: true, includeIfNull: false)
  final PublicLabel tag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagPage &&
          other.nextCursor == nextCursor &&
          other.results == results &&
          other.tag == tag;

  @override
  int get hashCode =>
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      results.hashCode +
      tag.hashCode;

  factory TagPage.fromJson(Map<String, dynamic> json) =>
      _$TagPageFromJson(json);

  Map<String, dynamic> toJson() => _$TagPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
