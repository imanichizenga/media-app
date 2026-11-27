//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment_author.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommentAuthor {
  /// Returns a new [CommentAuthor] instance.
  CommentAuthor({
    required this.name,

    required this.username,

    required this.initial,

    required this.isWriter,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'username', required: true, includeIfNull: false)
  final String username;

  @JsonKey(name: r'initial', required: true, includeIfNull: false)
  final String initial;

  /// Wrote the story: a badge.
  @JsonKey(name: r'is_writer', required: true, includeIfNull: false)
  final bool isWriter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentAuthor &&
          other.name == name &&
          other.username == username &&
          other.initial == initial &&
          other.isWriter == isWriter;

  @override
  int get hashCode =>
      name.hashCode + username.hashCode + initial.hashCode + isWriter.hashCode;

  factory CommentAuthor.fromJson(Map<String, dynamic> json) =>
      _$CommentAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$CommentAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
