// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_region.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicRegionCWProxy {
  PublicRegion slug(String slug);

  PublicRegion name(String name);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicRegion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicRegion(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicRegion call({
    String slug,
    String name,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicRegion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicRegion.copyWith.fieldName(...)`
class _$PublicRegionCWProxyImpl implements _$PublicRegionCWProxy {
  const _$PublicRegionCWProxyImpl(this._value);

  final PublicRegion _value;

  @override
  PublicRegion slug(String slug) => this(slug: slug);

  @override
  PublicRegion name(String name) => this(name: name);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicRegion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicRegion(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicRegion call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return PublicRegion(
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $PublicRegionCopyWith on PublicRegion {
  /// Returns a callable class that can be used as follows: `instanceOfPublicRegion.copyWith(...)` or like so:`instanceOfPublicRegion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicRegionCWProxy get copyWith => _$PublicRegionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicRegion _$PublicRegionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicRegion',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['slug', 'name'],
        );
        final val = PublicRegion(
          slug: $checkedConvert('slug', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$PublicRegionToJson(PublicRegion instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
    };
