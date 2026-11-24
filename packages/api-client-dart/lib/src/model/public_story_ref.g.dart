// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_story_ref.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicStoryRefCWProxy {
  PublicStoryRef slug(String slug);

  PublicStoryRef title(String title);

  PublicStoryRef path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicStoryRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicStoryRef(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicStoryRef call({
    String slug,
    String title,
    String path,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicStoryRef.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicStoryRef.copyWith.fieldName(...)`
class _$PublicStoryRefCWProxyImpl implements _$PublicStoryRefCWProxy {
  const _$PublicStoryRefCWProxyImpl(this._value);

  final PublicStoryRef _value;

  @override
  PublicStoryRef slug(String slug) => this(slug: slug);

  @override
  PublicStoryRef title(String title) => this(title: title);

  @override
  PublicStoryRef path(String path) => this(path: path);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicStoryRef(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicStoryRef(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicStoryRef call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return PublicStoryRef(
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
    );
  }
}

extension $PublicStoryRefCopyWith on PublicStoryRef {
  /// Returns a callable class that can be used as follows: `instanceOfPublicStoryRef.copyWith(...)` or like so:`instanceOfPublicStoryRef.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicStoryRefCWProxy get copyWith => _$PublicStoryRefCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicStoryRef _$PublicStoryRefFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicStoryRef',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['slug', 'title', 'path'],
        );
        final val = PublicStoryRef(
          slug: $checkedConvert('slug', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicStoryRefToJson(PublicStoryRef instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'title': instance.title,
      'path': instance.path,
    };
