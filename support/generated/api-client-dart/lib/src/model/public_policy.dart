//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/comments_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_policy.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicPolicy {
  /// Returns a new [PublicPolicy] instance.
  PublicPolicy({
    required this.likes,

    required this.comments,

    required this.bookmarks,

    required this.shares,

    required this.reposts,

    required this.liveChat,
  });

  @JsonKey(name: r'likes', required: true, includeIfNull: false)
  final bool likes;

  @JsonKey(name: r'comments', required: true, includeIfNull: false)
  final CommentsEnum comments;

  @JsonKey(name: r'bookmarks', required: true, includeIfNull: false)
  final bool bookmarks;

  @JsonKey(name: r'shares', required: true, includeIfNull: false)
  final bool shares;

  @JsonKey(name: r'reposts', required: true, includeIfNull: false)
  final bool reposts;

  @JsonKey(name: r'live_chat', required: true, includeIfNull: false)
  final bool liveChat;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicPolicy &&
          other.likes == likes &&
          other.comments == comments &&
          other.bookmarks == bookmarks &&
          other.shares == shares &&
          other.reposts == reposts &&
          other.liveChat == liveChat;

  @override
  int get hashCode =>
      likes.hashCode +
      comments.hashCode +
      bookmarks.hashCode +
      shares.hashCode +
      reposts.hashCode +
      liveChat.hashCode;

  factory PublicPolicy.fromJson(Map<String, dynamic> json) =>
      _$PublicPolicyFromJson(json);

  Map<String, dynamic> toJson() => _$PublicPolicyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
