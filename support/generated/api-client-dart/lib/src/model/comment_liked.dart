//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment_liked.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommentLiked {
  /// Returns a new [CommentLiked] instance.
  CommentLiked({required this.liked, required this.likeCount});

  @JsonKey(name: r'liked', required: true, includeIfNull: false)
  final bool liked;

  @JsonKey(name: r'like_count', required: true, includeIfNull: false)
  final int likeCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentLiked &&
          other.liked == liked &&
          other.likeCount == likeCount;

  @override
  int get hashCode => liked.hashCode + likeCount.hashCode;

  factory CommentLiked.fromJson(Map<String, dynamic> json) =>
      _$CommentLikedFromJson(json);

  Map<String, dynamic> toJson() => _$CommentLikedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
