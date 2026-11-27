//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'new_comment_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NewCommentRequest {
  /// Returns a new [NewCommentRequest] instance.
  NewCommentRequest({required this.body, this.parent});

  @JsonKey(name: r'body', required: true, includeIfNull: false)
  final String body;

  @JsonKey(name: r'parent', required: false, includeIfNull: false)
  final String? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewCommentRequest &&
          other.body == body &&
          other.parent == parent;

  @override
  int get hashCode => body.hashCode + (parent == null ? 0 : parent.hashCode);

  factory NewCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$NewCommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$NewCommentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
