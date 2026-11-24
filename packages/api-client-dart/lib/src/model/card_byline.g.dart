// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_byline.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardBylineCWProxy {
  CardByline id(String id);

  CardByline name(String name);

  CardByline slug(String slug);

  CardByline path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CardByline(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CardByline(...).copyWith(id: 12, name: "My name")
  /// ````
  CardByline call({
    String id,
    String name,
    String slug,
    String path,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCardByline.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCardByline.copyWith.fieldName(...)`
class _$CardBylineCWProxyImpl implements _$CardBylineCWProxy {
  const _$CardBylineCWProxyImpl(this._value);

  final CardByline _value;

  @override
  CardByline id(String id) => this(id: id);

  @override
  CardByline name(String name) => this(name: name);

  @override
  CardByline slug(String slug) => this(slug: slug);

  @override
  CardByline path(String path) => this(path: path);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CardByline(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CardByline(...).copyWith(id: 12, name: "My name")
  /// ````
  CardByline call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return CardByline(
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
    );
  }
}

extension $CardBylineCopyWith on CardByline {
  /// Returns a callable class that can be used as follows: `instanceOfCardByline.copyWith(...)` or like so:`instanceOfCardByline.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardBylineCWProxy get copyWith => _$CardBylineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardByline _$CardBylineFromJson(Map<String, dynamic> json) => $checkedCreate(
      'CardByline',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'name', 'slug', 'path'],
        );
        final val = CardByline(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          slug: $checkedConvert('slug', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CardBylineToJson(CardByline instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'path': instance.path,
    };
