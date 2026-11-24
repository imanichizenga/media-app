//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_byline.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicByline {
  /// Returns a new [PublicByline] instance.
  PublicByline({
    required this.id,
    required this.name,
    required this.slug,
    required this.path,
    required this.title,
    required this.avatar,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'slug',
    required: true,
    includeIfNull: false,
  )
  final String slug;

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'avatar',
    required: true,
    includeIfNull: true,
  )
  final PublicImage? avatar;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicByline &&
          other.id == id &&
          other.name == name &&
          other.slug == slug &&
          other.path == path &&
          other.title == title &&
          other.avatar == avatar;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      slug.hashCode +
      path.hashCode +
      title.hashCode +
      (avatar == null ? 0 : avatar.hashCode);

  factory PublicByline.fromJson(Map<String, dynamic> json) =>
      _$PublicBylineFromJson(json);

  Map<String, dynamic> toJson() => _$PublicBylineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
