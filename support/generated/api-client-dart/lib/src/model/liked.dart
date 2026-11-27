//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'liked.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Liked {
  /// Returns a new [Liked] instance.
  Liked({
    required this.views,

    required this.likes,

    required this.comments,

    required this.bookmarks,

    required this.liked,
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

  @JsonKey(name: r'liked', required: true, includeIfNull: false)
  final bool liked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Liked &&
          other.views == views &&
          other.likes == likes &&
          other.comments == comments &&
          other.bookmarks == bookmarks &&
          other.liked == liked;

  @override
  int get hashCode =>
      views.hashCode +
      likes.hashCode +
      comments.hashCode +
      bookmarks.hashCode +
      liked.hashCode;

  factory Liked.fromJson(Map<String, dynamic> json) => _$LikedFromJson(json);

  Map<String, dynamic> toJson() => _$LikedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
