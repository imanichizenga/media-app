// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_state.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PostStateCWProxy {
  PostState views(int views);

  PostState likes(int likes);

  PostState comments(int comments);

  PostState bookmarks(int bookmarks);

  PostState readers(int readers);

  PostState liked(bool liked);

  PostState bookmarked(bool bookmarked);

  PostState likesOn(bool likesOn);

  PostState commentsOn(bool commentsOn);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostState(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostState(...).copyWith(id: 12, name: "My name")
  /// ````
  PostState call({
    int views,
    int likes,
    int comments,
    int bookmarks,
    int readers,
    bool liked,
    bool bookmarked,
    bool likesOn,
    bool commentsOn,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPostState.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPostState.copyWith.fieldName(...)`
class _$PostStateCWProxyImpl implements _$PostStateCWProxy {
  const _$PostStateCWProxyImpl(this._value);

  final PostState _value;

  @override
  PostState views(int views) => this(views: views);

  @override
  PostState likes(int likes) => this(likes: likes);

  @override
  PostState comments(int comments) => this(comments: comments);

  @override
  PostState bookmarks(int bookmarks) => this(bookmarks: bookmarks);

  @override
  PostState readers(int readers) => this(readers: readers);

  @override
  PostState liked(bool liked) => this(liked: liked);

  @override
  PostState bookmarked(bool bookmarked) => this(bookmarked: bookmarked);

  @override
  PostState likesOn(bool likesOn) => this(likesOn: likesOn);

  @override
  PostState commentsOn(bool commentsOn) => this(commentsOn: commentsOn);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PostState(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PostState(...).copyWith(id: 12, name: "My name")
  /// ````
  PostState call({
    Object? views = const $CopyWithPlaceholder(),
    Object? likes = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? bookmarks = const $CopyWithPlaceholder(),
    Object? readers = const $CopyWithPlaceholder(),
    Object? liked = const $CopyWithPlaceholder(),
    Object? bookmarked = const $CopyWithPlaceholder(),
    Object? likesOn = const $CopyWithPlaceholder(),
    Object? commentsOn = const $CopyWithPlaceholder(),
  }) {
    return PostState(
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
      readers: readers == const $CopyWithPlaceholder()
          ? _value.readers
          // ignore: cast_nullable_to_non_nullable
          : readers as int,
      liked: liked == const $CopyWithPlaceholder()
          ? _value.liked
          // ignore: cast_nullable_to_non_nullable
          : liked as bool,
      bookmarked: bookmarked == const $CopyWithPlaceholder()
          ? _value.bookmarked
          // ignore: cast_nullable_to_non_nullable
          : bookmarked as bool,
      likesOn: likesOn == const $CopyWithPlaceholder()
          ? _value.likesOn
          // ignore: cast_nullable_to_non_nullable
          : likesOn as bool,
      commentsOn: commentsOn == const $CopyWithPlaceholder()
          ? _value.commentsOn
          // ignore: cast_nullable_to_non_nullable
          : commentsOn as bool,
    );
  }
}

extension $PostStateCopyWith on PostState {
  /// Returns a callable class that can be used as follows: `instanceOfPostState.copyWith(...)` or like so:`instanceOfPostState.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PostStateCWProxy get copyWith => _$PostStateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostState _$PostStateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PostState', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'views',
          'likes',
          'comments',
          'bookmarks',
          'readers',
          'liked',
          'bookmarked',
          'likes_on',
          'comments_on',
        ],
      );
      final val = PostState(
        views: $checkedConvert('views', (v) => (v as num).toInt()),
        likes: $checkedConvert('likes', (v) => (v as num).toInt()),
        comments: $checkedConvert('comments', (v) => (v as num).toInt()),
        bookmarks: $checkedConvert('bookmarks', (v) => (v as num).toInt()),
        readers: $checkedConvert('readers', (v) => (v as num).toInt()),
        liked: $checkedConvert('liked', (v) => v as bool),
        bookmarked: $checkedConvert('bookmarked', (v) => v as bool),
        likesOn: $checkedConvert('likes_on', (v) => v as bool),
        commentsOn: $checkedConvert('comments_on', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'likesOn': 'likes_on', 'commentsOn': 'comments_on'});

Map<String, dynamic> _$PostStateToJson(PostState instance) => <String, dynamic>{
  'views': instance.views,
  'likes': instance.likes,
  'comments': instance.comments,
  'bookmarks': instance.bookmarks,
  'readers': instance.readers,
  'liked': instance.liked,
  'bookmarked': instance.bookmarked,
  'likes_on': instance.likesOn,
  'comments_on': instance.commentsOn,
};
