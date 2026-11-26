// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_category.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicCategoryCWProxy {
  PublicCategory id(String id);

  PublicCategory name(String name);

  PublicCategory shortName(String shortName);

  PublicCategory slug(String slug);

  PublicCategory path(String path);

  PublicCategory color(String color);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicCategory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicCategory(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicCategory call({
    String id,
    String name,
    String shortName,
    String slug,
    String path,
    String color,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicCategory.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicCategory.copyWith.fieldName(...)`
class _$PublicCategoryCWProxyImpl implements _$PublicCategoryCWProxy {
  const _$PublicCategoryCWProxyImpl(this._value);

  final PublicCategory _value;

  @override
  PublicCategory id(String id) => this(id: id);

  @override
  PublicCategory name(String name) => this(name: name);

  @override
  PublicCategory shortName(String shortName) => this(shortName: shortName);

  @override
  PublicCategory slug(String slug) => this(slug: slug);

  @override
  PublicCategory path(String path) => this(path: path);

  @override
  PublicCategory color(String color) => this(color: color);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicCategory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicCategory(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicCategory call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? shortName = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
  }) {
    return PublicCategory(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      shortName: shortName == const $CopyWithPlaceholder()
          ? _value.shortName
          // ignore: cast_nullable_to_non_nullable
          : shortName as String,
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
    );
  }
}

extension $PublicCategoryCopyWith on PublicCategory {
  /// Returns a callable class that can be used as follows: `instanceOfPublicCategory.copyWith(...)` or like so:`instanceOfPublicCategory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicCategoryCWProxy get copyWith => _$PublicCategoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicCategory _$PublicCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicCategory',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'short_name',
            'slug',
            'path',
            'color'
          ],
        );
        final val = PublicCategory(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          shortName: $checkedConvert('short_name', (v) => v as String),
          slug: $checkedConvert('slug', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          color: $checkedConvert('color', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'shortName': 'short_name'},
    );

Map<String, dynamic> _$PublicCategoryToJson(PublicCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'short_name': instance.shortName,
      'slug': instance.slug,
      'path': instance.path,
      'color': instance.color,
    };
