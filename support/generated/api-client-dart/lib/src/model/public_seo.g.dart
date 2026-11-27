// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_seo.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicSeoCWProxy {
  PublicSeo title(String title);

  PublicSeo description(String description);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicSeo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicSeo(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicSeo call({String title, String description});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicSeo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicSeo.copyWith.fieldName(...)`
class _$PublicSeoCWProxyImpl implements _$PublicSeoCWProxy {
  const _$PublicSeoCWProxyImpl(this._value);

  final PublicSeo _value;

  @override
  PublicSeo title(String title) => this(title: title);

  @override
  PublicSeo description(String description) => this(description: description);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicSeo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicSeo(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicSeo call({
    Object? title = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
  }) {
    return PublicSeo(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
    );
  }
}

extension $PublicSeoCopyWith on PublicSeo {
  /// Returns a callable class that can be used as follows: `instanceOfPublicSeo.copyWith(...)` or like so:`instanceOfPublicSeo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicSeoCWProxy get copyWith => _$PublicSeoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicSeo _$PublicSeoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicSeo', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['title', 'description']);
      final val = PublicSeo(
        title: $checkedConvert('title', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PublicSeoToJson(PublicSeo instance) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
};
