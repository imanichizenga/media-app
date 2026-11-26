// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_item.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NavigationItemCWProxy {
  NavigationItem id(String id);

  NavigationItem name(String name);

  NavigationItem shortName(String shortName);

  NavigationItem slug(String slug);

  NavigationItem path(String path);

  NavigationItem color(String color);

  NavigationItem icon(String icon);

  NavigationItem children(List<PublicCategory> children);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NavigationItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NavigationItem(...).copyWith(id: 12, name: "My name")
  /// ````
  NavigationItem call({
    String id,
    String name,
    String shortName,
    String slug,
    String path,
    String color,
    String icon,
    List<PublicCategory> children,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNavigationItem.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNavigationItem.copyWith.fieldName(...)`
class _$NavigationItemCWProxyImpl implements _$NavigationItemCWProxy {
  const _$NavigationItemCWProxyImpl(this._value);

  final NavigationItem _value;

  @override
  NavigationItem id(String id) => this(id: id);

  @override
  NavigationItem name(String name) => this(name: name);

  @override
  NavigationItem shortName(String shortName) => this(shortName: shortName);

  @override
  NavigationItem slug(String slug) => this(slug: slug);

  @override
  NavigationItem path(String path) => this(path: path);

  @override
  NavigationItem color(String color) => this(color: color);

  @override
  NavigationItem icon(String icon) => this(icon: icon);

  @override
  NavigationItem children(List<PublicCategory> children) =>
      this(children: children);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NavigationItem(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NavigationItem(...).copyWith(id: 12, name: "My name")
  /// ````
  NavigationItem call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? shortName = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? children = const $CopyWithPlaceholder(),
  }) {
    return NavigationItem(
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
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String,
      children: children == const $CopyWithPlaceholder()
          ? _value.children
          // ignore: cast_nullable_to_non_nullable
          : children as List<PublicCategory>,
    );
  }
}

extension $NavigationItemCopyWith on NavigationItem {
  /// Returns a callable class that can be used as follows: `instanceOfNavigationItem.copyWith(...)` or like so:`instanceOfNavigationItem.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NavigationItemCWProxy get copyWith => _$NavigationItemCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NavigationItem _$NavigationItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NavigationItem',
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
            'color',
            'icon',
            'children'
          ],
        );
        final val = NavigationItem(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          shortName: $checkedConvert('short_name', (v) => v as String),
          slug: $checkedConvert('slug', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          color: $checkedConvert('color', (v) => v as String),
          icon: $checkedConvert('icon', (v) => v as String),
          children: $checkedConvert(
              'children',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PublicCategory.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'shortName': 'short_name'},
    );

Map<String, dynamic> _$NavigationItemToJson(NavigationItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'short_name': instance.shortName,
      'slug': instance.slug,
      'path': instance.path,
      'color': instance.color,
      'icon': instance.icon,
      'children': instance.children.map((e) => e.toJson()).toList(),
    };
