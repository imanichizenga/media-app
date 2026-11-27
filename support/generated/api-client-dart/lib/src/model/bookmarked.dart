//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bookmarked.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Bookmarked {
  /// Returns a new [Bookmarked] instance.
  Bookmarked({
    required this.views,

    required this.likes,

    required this.comments,

    required this.bookmarks,

    required this.bookmarked,
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

  @JsonKey(name: r'bookmarked', required: true, includeIfNull: false)
  final bool bookmarked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmarked &&
          other.views == views &&
          other.likes == likes &&
          other.comments == comments &&
          other.bookmarks == bookmarks &&
          other.bookmarked == bookmarked;

  @override
  int get hashCode =>
      views.hashCode +
      likes.hashCode +
      comments.hashCode +
      bookmarks.hashCode +
      bookmarked.hashCode;

  factory Bookmarked.fromJson(Map<String, dynamic> json) =>
      _$BookmarkedFromJson(json);

  Map<String, dynamic> toJson() => _$BookmarkedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
