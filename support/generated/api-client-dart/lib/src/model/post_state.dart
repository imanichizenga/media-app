//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_state.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PostState {
  /// Returns a new [PostState] instance.
  PostState({
    required this.views,

    required this.likes,

    required this.comments,

    required this.bookmarks,

    required this.readers,

    required this.liked,

    required this.bookmarked,

    required this.likesOn,

    required this.commentsOn,
  });

  /// Openings; one device counts once in 30 minutes.
  @JsonKey(name: r'views', required: true, includeIfNull: false)
  final int views;

  @JsonKey(name: r'likes', required: true, includeIfNull: false)
  final int likes;

  @JsonKey(name: r'comments', required: true, includeIfNull: false)
  final int comments;

  @JsonKey(name: r'bookmarks', required: true, includeIfNull: false)
  final int bookmarks;

  /// Distinct people who opened it.
  @JsonKey(name: r'readers', required: true, includeIfNull: false)
  final int readers;

  @JsonKey(name: r'liked', required: true, includeIfNull: false)
  final bool liked;

  @JsonKey(name: r'bookmarked', required: true, includeIfNull: false)
  final bool bookmarked;

  /// The story allows likes now: a count it does not allow is not shown.
  @JsonKey(name: r'likes_on', required: true, includeIfNull: false)
  final bool likesOn;

  /// The story's comments are not closed.
  @JsonKey(name: r'comments_on', required: true, includeIfNull: false)
  final bool commentsOn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostState &&
          other.views == views &&
          other.likes == likes &&
          other.comments == comments &&
          other.bookmarks == bookmarks &&
          other.readers == readers &&
          other.liked == liked &&
          other.bookmarked == bookmarked &&
          other.likesOn == likesOn &&
          other.commentsOn == commentsOn;

  @override
  int get hashCode =>
      views.hashCode +
      likes.hashCode +
      comments.hashCode +
      bookmarks.hashCode +
      readers.hashCode +
      liked.hashCode +
      bookmarked.hashCode +
      likesOn.hashCode +
      commentsOn.hashCode;

  factory PostState.fromJson(Map<String, dynamic> json) =>
      _$PostStateFromJson(json);

  Map<String, dynamic> toJson() => _$PostStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
