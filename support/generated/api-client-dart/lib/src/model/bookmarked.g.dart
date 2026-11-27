// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmarked.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookmarkedCWProxy {
  Bookmarked views(int views);

  Bookmarked likes(int likes);

  Bookmarked comments(int comments);

  Bookmarked bookmarks(int bookmarks);

  Bookmarked bookmarked(bool bookmarked);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Bookmarked(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Bookmarked(...).copyWith(id: 12, name: "My name")
  /// ````
  Bookmarked call({
    int views,
    int likes,
    int comments,
    int bookmarks,
    bool bookmarked,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBookmarked.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBookmarked.copyWith.fieldName(...)`
class _$BookmarkedCWProxyImpl implements _$BookmarkedCWProxy {
  const _$BookmarkedCWProxyImpl(this._value);

  final Bookmarked _value;

  @override
  Bookmarked views(int views) => this(views: views);

  @override
  Bookmarked likes(int likes) => this(likes: likes);

  @override
  Bookmarked comments(int comments) => this(comments: comments);

  @override
  Bookmarked bookmarks(int bookmarks) => this(bookmarks: bookmarks);

  @override
  Bookmarked bookmarked(bool bookmarked) => this(bookmarked: bookmarked);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Bookmarked(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Bookmarked(...).copyWith(id: 12, name: "My name")
  /// ````
  Bookmarked call({
    Object? views = const $CopyWithPlaceholder(),
    Object? likes = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? bookmarks = const $CopyWithPlaceholder(),
    Object? bookmarked = const $CopyWithPlaceholder(),
  }) {
    return Bookmarked(
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
      bookmarked: bookmarked == const $CopyWithPlaceholder()
          ? _value.bookmarked
          // ignore: cast_nullable_to_non_nullable
          : bookmarked as bool,
    );
  }
}

extension $BookmarkedCopyWith on Bookmarked {
  /// Returns a callable class that can be used as follows: `instanceOfBookmarked.copyWith(...)` or like so:`instanceOfBookmarked.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookmarkedCWProxy get copyWith => _$BookmarkedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bookmarked _$BookmarkedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Bookmarked', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'views',
          'likes',
          'comments',
          'bookmarks',
          'bookmarked',
        ],
      );
      final val = Bookmarked(
        views: $checkedConvert('views', (v) => (v as num).toInt()),
        likes: $checkedConvert('likes', (v) => (v as num).toInt()),
        comments: $checkedConvert('comments', (v) => (v as num).toInt()),
        bookmarks: $checkedConvert('bookmarks', (v) => (v as num).toInt()),
        bookmarked: $checkedConvert('bookmarked', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$BookmarkedToJson(Bookmarked instance) =>
    <String, dynamic>{
      'views': instance.views,
      'likes': instance.likes,
      'comments': instance.comments,
      'bookmarks': instance.bookmarks,
      'bookmarked': instance.bookmarked,
    };
