// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_label.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicLabelCWProxy {
  PublicLabel slug(String slug);

  PublicLabel name(String name);

  PublicLabel path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicLabel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicLabel(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicLabel call({String slug, String name, String path});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicLabel.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicLabel.copyWith.fieldName(...)`
class _$PublicLabelCWProxyImpl implements _$PublicLabelCWProxy {
  const _$PublicLabelCWProxyImpl(this._value);

  final PublicLabel _value;

  @override
  PublicLabel slug(String slug) => this(slug: slug);

  @override
  PublicLabel name(String name) => this(name: name);

  @override
  PublicLabel path(String path) => this(path: path);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicLabel(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicLabel(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicLabel call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return PublicLabel(
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
    );
  }
}

extension $PublicLabelCopyWith on PublicLabel {
  /// Returns a callable class that can be used as follows: `instanceOfPublicLabel.copyWith(...)` or like so:`instanceOfPublicLabel.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicLabelCWProxy get copyWith => _$PublicLabelCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicLabel _$PublicLabelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicLabel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['slug', 'name', 'path']);
      final val = PublicLabel(
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PublicLabelToJson(PublicLabel instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'path': instance.path,
    };
