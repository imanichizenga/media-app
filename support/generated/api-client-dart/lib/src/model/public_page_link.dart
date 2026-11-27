//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_page_link.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicPageLink {
  /// Returns a new [PublicPageLink] instance.
  PublicPageLink({
    required this.key,

    required this.title,

    required this.path,

    required this.modifiedAt,
  });

  @JsonKey(name: r'key', required: true, includeIfNull: false)
  final String key;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @JsonKey(name: r'modified_at', required: true, includeIfNull: false)
  final DateTime modifiedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicPageLink &&
          other.key == key &&
          other.title == title &&
          other.path == path &&
          other.modifiedAt == modifiedAt;

  @override
  int get hashCode =>
      key.hashCode + title.hashCode + path.hashCode + modifiedAt.hashCode;

  factory PublicPageLink.fromJson(Map<String, dynamic> json) =>
      _$PublicPageLinkFromJson(json);

  Map<String, dynamic> toJson() => _$PublicPageLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
