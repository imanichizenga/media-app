//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_image.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_author.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicAuthor {
  /// Returns a new [PublicAuthor] instance.
  PublicAuthor({
    required this.id,
    required this.name,
    required this.slug,
    required this.path,
    required this.title,
    required this.avatar,
    required this.bio,
    required this.expertise,
    required this.links,
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

  @JsonKey(
    name: r'bio',
    required: true,
    includeIfNull: false,
  )
  final String bio;

  @JsonKey(
    name: r'expertise',
    required: true,
    includeIfNull: false,
  )
  final List<String> expertise;

  @JsonKey(
    name: r'links',
    required: true,
    includeIfNull: false,
  )
  final List<String> links;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicAuthor &&
          other.id == id &&
          other.name == name &&
          other.slug == slug &&
          other.path == path &&
          other.title == title &&
          other.avatar == avatar &&
          other.bio == bio &&
          other.expertise == expertise &&
          other.links == links;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      slug.hashCode +
      path.hashCode +
      title.hashCode +
      (avatar == null ? 0 : avatar.hashCode) +
      bio.hashCode +
      expertise.hashCode +
      links.hashCode;

  factory PublicAuthor.fromJson(Map<String, dynamic> json) =>
      _$PublicAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$PublicAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
