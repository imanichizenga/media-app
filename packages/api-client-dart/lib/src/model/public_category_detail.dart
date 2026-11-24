//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_category.dart';
import 'package:news_api_client/src/model/category_translation.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_category_detail.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicCategoryDetail {
  /// Returns a new [PublicCategoryDetail] instance.
  PublicCategoryDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.path,
    required this.color,
    required this.icon,
    required this.description,
    required this.seoTitle,
    required this.seoDescription,
    required this.parents,
    required this.children,
    required this.translations,
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
    name: r'description',
    required: true,
    includeIfNull: false,
  )
  final String description;

  @JsonKey(
    name: r'seo_title',
    required: true,
    includeIfNull: false,
  )
  final String seoTitle;

  @JsonKey(
    name: r'seo_description',
    required: true,
    includeIfNull: false,
  )
  final String seoDescription;

  @JsonKey(
    name: r'parents',
    required: true,
    includeIfNull: false,
  )
  final List<PublicCategory> parents;

  @JsonKey(
    name: r'children',
    required: true,
    includeIfNull: false,
  )
  final List<PublicCategory> children;

  @JsonKey(
    name: r'translations',
    required: true,
    includeIfNull: false,
  )
  final List<CategoryTranslation> translations;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicCategoryDetail &&
          other.id == id &&
          other.name == name &&
          other.slug == slug &&
          other.path == path &&
          other.color == color &&
          other.icon == icon &&
          other.description == description &&
          other.seoTitle == seoTitle &&
          other.seoDescription == seoDescription &&
          other.parents == parents &&
          other.children == children &&
          other.translations == translations;

  @override
  int get hashCode =>
      id.hashCode +
      name.hashCode +
      slug.hashCode +
      path.hashCode +
      color.hashCode +
      icon.hashCode +
      description.hashCode +
      seoTitle.hashCode +
      seoDescription.hashCode +
      parents.hashCode +
      children.hashCode +
      translations.hashCode;

  factory PublicCategoryDetail.fromJson(Map<String, dynamic> json) =>
      _$PublicCategoryDetailFromJson(json);

  Map<String, dynamic> toJson() => _$PublicCategoryDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
