// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_page_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicPageLinkCWProxy {
  PublicPageLink key(String key);

  PublicPageLink title(String title);

  PublicPageLink path(String path);

  PublicPageLink modifiedAt(DateTime modifiedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPageLink(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPageLink(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPageLink call({
    String key,
    String title,
    String path,
    DateTime modifiedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicPageLink.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicPageLink.copyWith.fieldName(...)`
class _$PublicPageLinkCWProxyImpl implements _$PublicPageLinkCWProxy {
  const _$PublicPageLinkCWProxyImpl(this._value);

  final PublicPageLink _value;

  @override
  PublicPageLink key(String key) => this(key: key);

  @override
  PublicPageLink title(String title) => this(title: title);

  @override
  PublicPageLink path(String path) => this(path: path);

  @override
  PublicPageLink modifiedAt(DateTime modifiedAt) =>
      this(modifiedAt: modifiedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPageLink(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPageLink(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPageLink call({
    Object? key = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? modifiedAt = const $CopyWithPlaceholder(),
  }) {
    return PublicPageLink(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      modifiedAt: modifiedAt == const $CopyWithPlaceholder()
          ? _value.modifiedAt
          // ignore: cast_nullable_to_non_nullable
          : modifiedAt as DateTime,
    );
  }
}

extension $PublicPageLinkCopyWith on PublicPageLink {
  /// Returns a callable class that can be used as follows: `instanceOfPublicPageLink.copyWith(...)` or like so:`instanceOfPublicPageLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicPageLinkCWProxy get copyWith => _$PublicPageLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPageLink _$PublicPageLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicPageLink', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['key', 'title', 'path', 'modified_at'],
      );
      final val = PublicPageLink(
        key: $checkedConvert('key', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        modifiedAt: $checkedConvert(
          'modified_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'modifiedAt': 'modified_at'});

Map<String, dynamic> _$PublicPageLinkToJson(PublicPageLink instance) =>
    <String, dynamic>{
      'key': instance.key,
      'title': instance.title,
      'path': instance.path,
      'modified_at': instance.modifiedAt.toIso8601String(),
    };
