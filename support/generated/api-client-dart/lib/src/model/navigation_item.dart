//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_category.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'navigation_item.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class NavigationItem {
  /// Returns a new [NavigationItem] instance.
  NavigationItem({
    required this.id,
    required this.name,
    required this.shortName,
    required this.slug,
    required this.path,
    required this.color,
    required this.icon,
    required this.children,
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

  /// The editor's short label, or the name
  @JsonKey(
    name: r'short_name',
    required: true,
    includeIfNull: false,
  )
  final String shortName;

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
    name: r'color',
    required: true,
    includeIfNull: false,
  )
  final String color;

  @JsonKey(
    name: r'icon',
    required: true,
    includeIfNull: false,
  )
  final String icon;

  @JsonKey(
    name: r'children',
    required: true,
    includeIfNull: false,
  )
  final List<PublicCategory> children;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationItem &&
          other.id == id &&
          other.name == name &&
          other.shortName == shortName &&
          other.slug == slug &&
          other.path == path &&
          other.color == color &&
          other.icon == icon &&
          other.children == children;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      shortName.hashCode +
      slug.hashCode +
      path.hashCode +
      color.hashCode +
      icon.hashCode +
      children.hashCode;

  factory NavigationItem.fromJson(Map<String, dynamic> json) =>
      _$NavigationItemFromJson(json);

  Map<String, dynamic> toJson() => _$NavigationItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
