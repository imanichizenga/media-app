//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/comment_author.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Comment {
  /// Returns a new [Comment] instance.
  Comment({
    required this.id,

    required this.body,

    required this.createdAt,

    required this.author,

    required this.likeCount,

    required this.replyCount,

    required this.liked,

    required this.mine,

    required this.pinned,

    required this.held,

    required this.parent,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'created_at', required: true, includeIfNull: false)
  final DateTime createdAt;

  @JsonKey(name: r'author', required: true, includeIfNull: false)
  final CommentAuthor author;

  @JsonKey(name: r'like_count', required: true, includeIfNull: false)
  final int likeCount;

  @JsonKey(name: r'reply_count', required: true, includeIfNull: false)
  final int replyCount;

  @JsonKey(name: r'liked', required: true, includeIfNull: false)
  final bool liked;

  @JsonKey(name: r'mine', required: true, includeIfNull: false)
  final bool mine;

  @JsonKey(name: r'pinned', required: true, includeIfNull: false)
  final bool pinned;

  /// Waiting for a moderator; only its writer sees it.
  @JsonKey(name: r'held', required: true, includeIfNull: false)
  final bool held;

  @JsonKey(name: r'parent', required: true, includeIfNull: true)
  final String? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment &&
          other.id == id &&
          other.body == body &&
          other.createdAt == createdAt &&
          other.author == author &&
          other.likeCount == likeCount &&
          other.replyCount == replyCount &&
          other.liked == liked &&
          other.mine == mine &&
          other.pinned == pinned &&
          other.held == held &&
          other.parent == parent;

  @override
  int get hashCode =>
      id.hashCode +
      body.hashCode +
      createdAt.hashCode +
      author.hashCode +
      likeCount.hashCode +
      replyCount.hashCode +
      liked.hashCode +
      mine.hashCode +
      pinned.hashCode +
      held.hashCode +
      (parent == null ? 0 : parent.hashCode);

  factory Comment.fromJson(Map<String, dynamic> json) =>
      _$CommentFromJson(json);

  Map<String, dynamic> toJson() => _$CommentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
