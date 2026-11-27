// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_export.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelExportCWProxy {
  ModelExport account(Reader account);

  ModelExport identities(List<Map<String, Object?>> identities);

  ModelExport consents(List<Map<String, Object?>> consents);

  ModelExport likes(List<Map<String, Object?>> likes);

  ModelExport bookmarks(List<Map<String, Object?>> bookmarks);

  ModelExport comments(List<Map<String, Object?>> comments);

  ModelExport follows(List<Map<String, Object?>> follows);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModelExport(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModelExport(...).copyWith(id: 12, name: "My name")
  /// ````
  ModelExport call({
    Reader account,
    List<Map<String, Object?>> identities,
    List<Map<String, Object?>> consents,
    List<Map<String, Object?>> likes,
    List<Map<String, Object?>> bookmarks,
    List<Map<String, Object?>> comments,
    List<Map<String, Object?>> follows,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfModelExport.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfModelExport.copyWith.fieldName(...)`
class _$ModelExportCWProxyImpl implements _$ModelExportCWProxy {
  const _$ModelExportCWProxyImpl(this._value);

  final ModelExport _value;

  @override
  ModelExport account(Reader account) => this(account: account);

  @override
  ModelExport identities(List<Map<String, Object?>> identities) =>
      this(identities: identities);

  @override
  ModelExport consents(List<Map<String, Object?>> consents) =>
      this(consents: consents);

  @override
  ModelExport likes(List<Map<String, Object?>> likes) => this(likes: likes);

  @override
  ModelExport bookmarks(List<Map<String, Object?>> bookmarks) =>
      this(bookmarks: bookmarks);

  @override
  ModelExport comments(List<Map<String, Object?>> comments) =>
      this(comments: comments);

  @override
  ModelExport follows(List<Map<String, Object?>> follows) =>
      this(follows: follows);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ModelExport(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ModelExport(...).copyWith(id: 12, name: "My name")
  /// ````
  ModelExport call({
    Object? account = const $CopyWithPlaceholder(),
    Object? identities = const $CopyWithPlaceholder(),
    Object? consents = const $CopyWithPlaceholder(),
    Object? likes = const $CopyWithPlaceholder(),
    Object? bookmarks = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? follows = const $CopyWithPlaceholder(),
  }) {
    return ModelExport(
      account: account == const $CopyWithPlaceholder()
          ? _value.account
          // ignore: cast_nullable_to_non_nullable
          : account as Reader,
      identities: identities == const $CopyWithPlaceholder()
          ? _value.identities
          // ignore: cast_nullable_to_non_nullable
          : identities as List<Map<String, Object?>>,
      consents: consents == const $CopyWithPlaceholder()
          ? _value.consents
          // ignore: cast_nullable_to_non_nullable
          : consents as List<Map<String, Object?>>,
      likes: likes == const $CopyWithPlaceholder()
          ? _value.likes
          // ignore: cast_nullable_to_non_nullable
          : likes as List<Map<String, Object?>>,
      bookmarks: bookmarks == const $CopyWithPlaceholder()
          ? _value.bookmarks
          // ignore: cast_nullable_to_non_nullable
          : bookmarks as List<Map<String, Object?>>,
      comments: comments == const $CopyWithPlaceholder()
          ? _value.comments
          // ignore: cast_nullable_to_non_nullable
          : comments as List<Map<String, Object?>>,
      follows: follows == const $CopyWithPlaceholder()
          ? _value.follows
          // ignore: cast_nullable_to_non_nullable
          : follows as List<Map<String, Object?>>,
    );
  }
}

extension $ModelExportCopyWith on ModelExport {
  /// Returns a callable class that can be used as follows: `instanceOfModelExport.copyWith(...)` or like so:`instanceOfModelExport.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelExportCWProxy get copyWith => _$ModelExportCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelExport _$ModelExportFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ModelExport',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'account',
        'identities',
        'consents',
        'likes',
        'bookmarks',
        'comments',
        'follows',
      ],
    );
    final val = ModelExport(
      account: $checkedConvert(
        'account',
        (v) => Reader.fromJson(v as Map<String, dynamic>),
      ),
      identities: $checkedConvert(
        'identities',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
      consents: $checkedConvert(
        'consents',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
      likes: $checkedConvert(
        'likes',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
      bookmarks: $checkedConvert(
        'bookmarks',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
      comments: $checkedConvert(
        'comments',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
      follows: $checkedConvert(
        'follows',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$ModelExportToJson(ModelExport instance) =>
    <String, dynamic>{
      'account': instance.account.toJson(),
      'identities': instance.identities,
      'consents': instance.consents,
      'likes': instance.likes,
      'bookmarks': instance.bookmarks,
      'comments': instance.comments,
      'follows': instance.follows,
    };
