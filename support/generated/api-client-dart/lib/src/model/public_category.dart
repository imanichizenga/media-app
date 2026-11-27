//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_category.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicCategory {
  /// Returns a new [PublicCategory] instance.
  PublicCategory({
    required this.id,

    required this.name,

    required this.shortName,

    required this.slug,

    required this.path,

    required this.color,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  /// The editor's short label, or the name
  @JsonKey(name: r'short_name', required: true, includeIfNull: false)
  final String shortName;

  @JsonKey(name: r'slug', required: true, includeIfNull: false)
  final String slug;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @JsonKey(name: r'color', required: true, includeIfNull: false)
  final String color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicCategory &&
          other.id == id &&
          other.name == name &&
          other.shortName == shortName &&
          other.slug == slug &&
          other.path == path &&
          other.color == color;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      shortName.hashCode +
      slug.hashCode +
      path.hashCode +
      color.hashCode;

  factory PublicCategory.fromJson(Map<String, dynamic> json) =>
      _$PublicCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$PublicCategoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
