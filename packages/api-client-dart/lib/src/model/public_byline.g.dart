// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_byline.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicBylineCWProxy {
  PublicByline id(String id);

  PublicByline name(String name);

  PublicByline slug(String slug);

  PublicByline path(String path);

  PublicByline title(String title);

  PublicByline avatar(PublicImage? avatar);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicByline(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicByline(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicByline call({
    String id,
    String name,
    String slug,
    String path,
    String title,
    PublicImage? avatar,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicByline.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicByline.copyWith.fieldName(...)`
class _$PublicBylineCWProxyImpl implements _$PublicBylineCWProxy {
  const _$PublicBylineCWProxyImpl(this._value);

  final PublicByline _value;

  @override
  PublicByline id(String id) => this(id: id);

  @override
  PublicByline name(String name) => this(name: name);

  @override
  PublicByline slug(String slug) => this(slug: slug);

  @override
  PublicByline path(String path) => this(path: path);

  @override
  PublicByline title(String title) => this(title: title);

  @override
  PublicByline avatar(PublicImage? avatar) => this(avatar: avatar);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicByline(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicByline(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicByline call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? avatar = const $CopyWithPlaceholder(),
  }) {
    return PublicByline(
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
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      avatar: avatar == const $CopyWithPlaceholder()
          ? _value.avatar
          // ignore: cast_nullable_to_non_nullable
          : avatar as PublicImage?,
    );
  }
}

extension $PublicBylineCopyWith on PublicByline {
  /// Returns a callable class that can be used as follows: `instanceOfPublicByline.copyWith(...)` or like so:`instanceOfPublicByline.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicBylineCWProxy get copyWith => _$PublicBylineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicByline _$PublicBylineFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicByline',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'name', 'slug', 'path', 'title', 'avatar'],
        );
        final val = PublicByline(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          slug: $checkedConvert('slug', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          avatar: $checkedConvert(
              'avatar',
              (v) => v == null
                  ? null
                  : PublicImage.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicBylineToJson(PublicByline instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'path': instance.path,
      'title': instance.title,
      'avatar': instance.avatar?.toJson(),
    };
