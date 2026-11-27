// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liked.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LikedCWProxy {
  Liked views(int views);

  Liked likes(int likes);

  Liked comments(int comments);

  Liked bookmarks(int bookmarks);

  Liked liked(bool liked);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Liked(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Liked(...).copyWith(id: 12, name: "My name")
  /// ````
  Liked call({int views, int likes, int comments, int bookmarks, bool liked});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLiked.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLiked.copyWith.fieldName(...)`
class _$LikedCWProxyImpl implements _$LikedCWProxy {
  const _$LikedCWProxyImpl(this._value);

  final Liked _value;

  @override
  Liked views(int views) => this(views: views);

  @override
  Liked likes(int likes) => this(likes: likes);

  @override
  Liked comments(int comments) => this(comments: comments);

  @override
  Liked bookmarks(int bookmarks) => this(bookmarks: bookmarks);

  @override
  Liked liked(bool liked) => this(liked: liked);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Liked(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Liked(...).copyWith(id: 12, name: "My name")
  /// ````
  Liked call({
    Object? views = const $CopyWithPlaceholder(),
    Object? likes = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? bookmarks = const $CopyWithPlaceholder(),
    Object? liked = const $CopyWithPlaceholder(),
  }) {
    return Liked(
      views: views == const $CopyWithPlaceholder()
          ? _value.views
          // ignore: cast_nullable_to_non_nullable
          : views as int,
      likes: likes == const $CopyWithPlaceholder()
          ? _value.likes
          // ignore: cast_nullable_to_non_nullable
          : likes as int,
      comments: comments == const $CopyWithPlaceholder()
          ? _value.comments
          // ignore: cast_nullable_to_non_nullable
          : comments as int,
      bookmarks: bookmarks == const $CopyWithPlaceholder()
          ? _value.bookmarks
          // ignore: cast_nullable_to_non_nullable
          : bookmarks as int,
      liked: liked == const $CopyWithPlaceholder()
          ? _value.liked
          // ignore: cast_nullable_to_non_nullable
          : liked as bool,
    );
  }
}

extension $LikedCopyWith on Liked {
  /// Returns a callable class that can be used as follows: `instanceOfLiked.copyWith(...)` or like so:`instanceOfLiked.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LikedCWProxy get copyWith => _$LikedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Liked _$LikedFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Liked',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['views', 'likes', 'comments', 'bookmarks', 'liked'],
    );
    final val = Liked(
      views: $checkedConvert('views', (v) => (v as num).toInt()),
      likes: $checkedConvert('likes', (v) => (v as num).toInt()),
      comments: $checkedConvert('comments', (v) => (v as num).toInt()),
      bookmarks: $checkedConvert('bookmarks', (v) => (v as num).toInt()),
      liked: $checkedConvert('liked', (v) => v as bool),
    );
    return val;
  },
);

Map<String, dynamic> _$LikedToJson(Liked instance) => <String, dynamic>{
  'views': instance.views,
  'likes': instance.likes,
  'comments': instance.comments,
  'bookmarks': instance.bookmarks,
  'liked': instance.liked,
};
