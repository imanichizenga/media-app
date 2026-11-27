// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_liked.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommentLikedCWProxy {
  CommentLiked liked(bool liked);

  CommentLiked likeCount(int likeCount);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommentLiked(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommentLiked(...).copyWith(id: 12, name: "My name")
  /// ````
  CommentLiked call({bool liked, int likeCount});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCommentLiked.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCommentLiked.copyWith.fieldName(...)`
class _$CommentLikedCWProxyImpl implements _$CommentLikedCWProxy {
  const _$CommentLikedCWProxyImpl(this._value);

  final CommentLiked _value;

  @override
  CommentLiked liked(bool liked) => this(liked: liked);

  @override
  CommentLiked likeCount(int likeCount) => this(likeCount: likeCount);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommentLiked(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommentLiked(...).copyWith(id: 12, name: "My name")
  /// ````
  CommentLiked call({
    Object? liked = const $CopyWithPlaceholder(),
    Object? likeCount = const $CopyWithPlaceholder(),
  }) {
    return CommentLiked(
      liked: liked == const $CopyWithPlaceholder()
          ? _value.liked
          // ignore: cast_nullable_to_non_nullable
          : liked as bool,
      likeCount: likeCount == const $CopyWithPlaceholder()
          ? _value.likeCount
          // ignore: cast_nullable_to_non_nullable
          : likeCount as int,
    );
  }
}

extension $CommentLikedCopyWith on CommentLiked {
  /// Returns a callable class that can be used as follows: `instanceOfCommentLiked.copyWith(...)` or like so:`instanceOfCommentLiked.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommentLikedCWProxy get copyWith => _$CommentLikedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentLiked _$CommentLikedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommentLiked', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['liked', 'like_count']);
      final val = CommentLiked(
        liked: $checkedConvert('liked', (v) => v as bool),
        likeCount: $checkedConvert('like_count', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'likeCount': 'like_count'});

Map<String, dynamic> _$CommentLikedToJson(CommentLiked instance) =>
    <String, dynamic>{
      'liked': instance.liked,
      'like_count': instance.likeCount,
    };
