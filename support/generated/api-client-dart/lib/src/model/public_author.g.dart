// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_author.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicAuthorCWProxy {
  PublicAuthor id(String id);

  PublicAuthor name(String name);

  PublicAuthor slug(String slug);

  PublicAuthor path(String path);

  PublicAuthor title(String title);

  PublicAuthor avatar(PublicImage? avatar);

  PublicAuthor bio(String bio);

  PublicAuthor expertise(List<String> expertise);

  PublicAuthor links(List<String> links);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicAuthor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicAuthor(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicAuthor call({
    String id,
    String name,
    String slug,
    String path,
    String title,
    PublicImage? avatar,
    String bio,
    List<String> expertise,
    List<String> links,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicAuthor.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicAuthor.copyWith.fieldName(...)`
class _$PublicAuthorCWProxyImpl implements _$PublicAuthorCWProxy {
  const _$PublicAuthorCWProxyImpl(this._value);

  final PublicAuthor _value;

  @override
  PublicAuthor id(String id) => this(id: id);

  @override
  PublicAuthor name(String name) => this(name: name);

  @override
  PublicAuthor slug(String slug) => this(slug: slug);

  @override
  PublicAuthor path(String path) => this(path: path);

  @override
  PublicAuthor title(String title) => this(title: title);

  @override
  PublicAuthor avatar(PublicImage? avatar) => this(avatar: avatar);

  @override
  PublicAuthor bio(String bio) => this(bio: bio);

  @override
  PublicAuthor expertise(List<String> expertise) => this(expertise: expertise);

  @override
  PublicAuthor links(List<String> links) => this(links: links);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicAuthor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicAuthor(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicAuthor call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? avatar = const $CopyWithPlaceholder(),
    Object? bio = const $CopyWithPlaceholder(),
    Object? expertise = const $CopyWithPlaceholder(),
    Object? links = const $CopyWithPlaceholder(),
  }) {
    return PublicAuthor(
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
      bio: bio == const $CopyWithPlaceholder()
          ? _value.bio
          // ignore: cast_nullable_to_non_nullable
          : bio as String,
      expertise: expertise == const $CopyWithPlaceholder()
          ? _value.expertise
          // ignore: cast_nullable_to_non_nullable
          : expertise as List<String>,
      links: links == const $CopyWithPlaceholder()
          ? _value.links
          // ignore: cast_nullable_to_non_nullable
          : links as List<String>,
    );
  }
}

extension $PublicAuthorCopyWith on PublicAuthor {
  /// Returns a callable class that can be used as follows: `instanceOfPublicAuthor.copyWith(...)` or like so:`instanceOfPublicAuthor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicAuthorCWProxy get copyWith => _$PublicAuthorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicAuthor _$PublicAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicAuthor', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'name',
          'slug',
          'path',
          'title',
          'avatar',
          'bio',
          'expertise',
          'links',
        ],
      );
      final val = PublicAuthor(
        id: $checkedConvert('id', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        slug: $checkedConvert('slug', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        avatar: $checkedConvert(
          'avatar',
          (v) => v == null
              ? null
              : PublicImage.fromJson(v as Map<String, dynamic>),
        ),
        bio: $checkedConvert('bio', (v) => v as String),
        expertise: $checkedConvert(
          'expertise',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        links: $checkedConvert(
          'links',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PublicAuthorToJson(PublicAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'path': instance.path,
      'title': instance.title,
      'avatar': instance.avatar?.toJson(),
      'bio': instance.bio,
      'expertise': instance.expertise,
      'links': instance.links,
    };
