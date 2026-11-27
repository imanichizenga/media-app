//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_policy.dart';
import 'package:news_api_client/src/model/comment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommentPage {
  /// Returns a new [CommentPage] instance.
  CommentPage({
    required this.policy,

    required this.count,

    required this.results,

    required this.nextCursor,
  });

  @JsonKey(name: r'policy', required: true, includeIfNull: false)
  final PublicPolicy policy;

  @JsonKey(name: r'count', required: true, includeIfNull: false)
  final int count;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Comment> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentPage &&
          other.policy == policy &&
          other.count == count &&
          other.results == results &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      policy.hashCode +
      count.hashCode +
      results.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode);

  factory CommentPage.fromJson(Map<String, dynamic> json) =>
      _$CommentPageFromJson(json);

  Map<String, dynamic> toJson() => _$CommentPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
