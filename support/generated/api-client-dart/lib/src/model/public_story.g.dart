// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_story.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicStoryCWProxy {
  PublicStory slug(String slug);

  PublicStory title(String title);

  PublicStory path(String path);

  PublicStory summary(String summary);

  PublicStory isActive(bool isActive);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicStory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicStory(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicStory call({
    String slug,
    String title,
    String path,
    String summary,
    bool isActive,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicStory.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicStory.copyWith.fieldName(...)`
class _$PublicStoryCWProxyImpl implements _$PublicStoryCWProxy {
  const _$PublicStoryCWProxyImpl(this._value);

  final PublicStory _value;

  @override
  PublicStory slug(String slug) => this(slug: slug);

  @override
  PublicStory title(String title) => this(title: title);

  @override
  PublicStory path(String path) => this(path: path);

  @override
  PublicStory summary(String summary) => this(summary: summary);

  @override
  PublicStory isActive(bool isActive) => this(isActive: isActive);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicStory(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicStory(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicStory call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? isActive = const $CopyWithPlaceholder(),
  }) {
    return PublicStory(
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
      summary: summary == const $CopyWithPlaceholder()
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      isActive: isActive == const $CopyWithPlaceholder()
          ? _value.isActive
          // ignore: cast_nullable_to_non_nullable
          : isActive as bool,
    );
  }
}

extension $PublicStoryCopyWith on PublicStory {
  /// Returns a callable class that can be used as follows: `instanceOfPublicStory.copyWith(...)` or like so:`instanceOfPublicStory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicStoryCWProxy get copyWith => _$PublicStoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicStory _$PublicStoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicStory', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['slug', 'title', 'path', 'summary', 'is_active'],
      );
      final val = PublicStory(
        slug: $checkedConvert('slug', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        summary: $checkedConvert('summary', (v) => v as String),
        isActive: $checkedConvert('is_active', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'isActive': 'is_active'});

Map<String, dynamic> _$PublicStoryToJson(PublicStory instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'title': instance.title,
      'path': instance.path,
      'summary': instance.summary,
      'is_active': instance.isActive,
    };
