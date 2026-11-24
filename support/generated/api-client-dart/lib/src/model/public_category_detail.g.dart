// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_category_detail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicCategoryDetailCWProxy {
  PublicCategoryDetail id(String id);

  PublicCategoryDetail name(String name);

  PublicCategoryDetail slug(String slug);

  PublicCategoryDetail path(String path);

  PublicCategoryDetail color(String color);

  PublicCategoryDetail icon(String icon);

  PublicCategoryDetail description(String description);

  PublicCategoryDetail seoTitle(String seoTitle);

  PublicCategoryDetail seoDescription(String seoDescription);

  PublicCategoryDetail parents(List<PublicCategory> parents);

  PublicCategoryDetail children(List<PublicCategory> children);

  PublicCategoryDetail translations(List<CategoryTranslation> translations);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicCategoryDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicCategoryDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicCategoryDetail call({
    String id,
    String name,
    String slug,
    String path,
    String color,
    String icon,
    String description,
    String seoTitle,
    String seoDescription,
    List<PublicCategory> parents,
    List<PublicCategory> children,
    List<CategoryTranslation> translations,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicCategoryDetail.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicCategoryDetail.copyWith.fieldName(...)`
class _$PublicCategoryDetailCWProxyImpl
    implements _$PublicCategoryDetailCWProxy {
  const _$PublicCategoryDetailCWProxyImpl(this._value);

  final PublicCategoryDetail _value;

  @override
  PublicCategoryDetail id(String id) => this(id: id);

  @override
  PublicCategoryDetail name(String name) => this(name: name);

  @override
  PublicCategoryDetail slug(String slug) => this(slug: slug);

  @override
  PublicCategoryDetail path(String path) => this(path: path);

  @override
  PublicCategoryDetail color(String color) => this(color: color);

  @override
  PublicCategoryDetail icon(String icon) => this(icon: icon);

  @override
  PublicCategoryDetail description(String description) =>
      this(description: description);

  @override
  PublicCategoryDetail seoTitle(String seoTitle) => this(seoTitle: seoTitle);

  @override
  PublicCategoryDetail seoDescription(String seoDescription) =>
      this(seoDescription: seoDescription);

  @override
  PublicCategoryDetail parents(List<PublicCategory> parents) =>
      this(parents: parents);

  @override
  PublicCategoryDetail children(List<PublicCategory> children) =>
      this(children: children);

  @override
  PublicCategoryDetail translations(List<CategoryTranslation> translations) =>
      this(translations: translations);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicCategoryDetail(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicCategoryDetail(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicCategoryDetail call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? seoTitle = const $CopyWithPlaceholder(),
    Object? seoDescription = const $CopyWithPlaceholder(),
    Object? parents = const $CopyWithPlaceholder(),
    Object? children = const $CopyWithPlaceholder(),
    Object? translations = const $CopyWithPlaceholder(),
  }) {
    return PublicCategoryDetail(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      seoTitle: seoTitle == const $CopyWithPlaceholder()
          ? _value.seoTitle
          // ignore: cast_nullable_to_non_nullable
          : seoTitle as String,
      seoDescription: seoDescription == const $CopyWithPlaceholder()
          ? _value.seoDescription
          // ignore: cast_nullable_to_non_nullable
          : seoDescription as String,
      parents: parents == const $CopyWithPlaceholder()
          ? _value.parents
          // ignore: cast_nullable_to_non_nullable
          : parents as List<PublicCategory>,
      children: children == const $CopyWithPlaceholder()
          ? _value.children
          // ignore: cast_nullable_to_non_nullable
          : children as List<PublicCategory>,
      translations: translations == const $CopyWithPlaceholder()
          ? _value.translations
          // ignore: cast_nullable_to_non_nullable
          : translations as List<CategoryTranslation>,
    );
  }
}

extension $PublicCategoryDetailCopyWith on PublicCategoryDetail {
  /// Returns a callable class that can be used as follows: `instanceOfPublicCategoryDetail.copyWith(...)` or like so:`instanceOfPublicCategoryDetail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicCategoryDetailCWProxy get copyWith =>
      _$PublicCategoryDetailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicCategoryDetail _$PublicCategoryDetailFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicCategoryDetail',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'slug',
            'path',
            'color',
            'icon',
            'description',
            'seo_title',
            'seo_description',
            'parents',
            'children',
            'translations'
          ],
        );
        final val = PublicCategoryDetail(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          slug: $checkedConvert('slug', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          color: $checkedConvert('color', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          seoTitle: $checkedConvert('seo_title', (v) => v as String),
          seoDescription:
              $checkedConvert('seo_description', (v) => v as String),
          parents: $checkedConvert(
              'parents',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PublicCategory.fromJson(e as Map<String, dynamic>))
                  .toList()),
          children: $checkedConvert(
              'children',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PublicCategory.fromJson(e as Map<String, dynamic>))
                  .toList()),
          translations: $checkedConvert(
              'translations',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      CategoryTranslation.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'seoTitle': 'seo_title',
        'seoDescription': 'seo_description'
      },
    );

Map<String, dynamic> _$PublicCategoryDetailToJson(
        PublicCategoryDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'path': instance.path,
      'color': instance.color,
      'icon': instance.icon,
      'description': instance.description,
      'seo_title': instance.seoTitle,
      'seo_description': instance.seoDescription,
      'parents': instance.parents.map((e) => e.toJson()).toList(),
      'children': instance.children.map((e) => e.toJson()).toList(),
      'translations': instance.translations.map((e) => e.toJson()).toList(),
    };
