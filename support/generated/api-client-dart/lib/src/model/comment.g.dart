// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommentCWProxy {
  Comment id(String id);

  Comment body(String body);

  Comment createdAt(DateTime createdAt);

  Comment author(CommentAuthor author);

  Comment likeCount(int likeCount);

  Comment replyCount(int replyCount);

  Comment liked(bool liked);

  Comment mine(bool mine);

  Comment pinned(bool pinned);

  Comment held(bool held);

  Comment parent(String? parent);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment call({
    String id,
    String body,
    DateTime createdAt,
    CommentAuthor author,
    int likeCount,
    int replyCount,
    bool liked,
    bool mine,
    bool pinned,
    bool held,
    String? parent,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComment.copyWith.fieldName(...)`
class _$CommentCWProxyImpl implements _$CommentCWProxy {
  const _$CommentCWProxyImpl(this._value);

  final Comment _value;

  @override
  Comment id(String id) => this(id: id);

  @override
  Comment body(String body) => this(body: body);

  @override
  Comment createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  Comment author(CommentAuthor author) => this(author: author);

  @override
  Comment likeCount(int likeCount) => this(likeCount: likeCount);

  @override
  Comment replyCount(int replyCount) => this(replyCount: replyCount);

  @override
  Comment liked(bool liked) => this(liked: liked);

  @override
  Comment mine(bool mine) => this(mine: mine);

  @override
  Comment pinned(bool pinned) => this(pinned: pinned);

  @override
  Comment held(bool held) => this(held: held);

  @override
  Comment parent(String? parent) => this(parent: parent);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Comment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Comment(...).copyWith(id: 12, name: "My name")
  /// ````
  Comment call({
    Object? id = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
    Object? likeCount = const $CopyWithPlaceholder(),
    Object? replyCount = const $CopyWithPlaceholder(),
    Object? liked = const $CopyWithPlaceholder(),
    Object? mine = const $CopyWithPlaceholder(),
    Object? pinned = const $CopyWithPlaceholder(),
    Object? held = const $CopyWithPlaceholder(),
    Object? parent = const $CopyWithPlaceholder(),
  }) {
    return Comment(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      author: author == const $CopyWithPlaceholder()
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as CommentAuthor,
      likeCount: likeCount == const $CopyWithPlaceholder()
          ? _value.likeCount
          // ignore: cast_nullable_to_non_nullable
          : likeCount as int,
      replyCount: replyCount == const $CopyWithPlaceholder()
          ? _value.replyCount
          // ignore: cast_nullable_to_non_nullable
          : replyCount as int,
      liked: liked == const $CopyWithPlaceholder()
          ? _value.liked
          // ignore: cast_nullable_to_non_nullable
          : liked as bool,
      mine: mine == const $CopyWithPlaceholder()
          ? _value.mine
          // ignore: cast_nullable_to_non_nullable
          : mine as bool,
      pinned: pinned == const $CopyWithPlaceholder()
          ? _value.pinned
          // ignore: cast_nullable_to_non_nullable
          : pinned as bool,
      held: held == const $CopyWithPlaceholder()
          ? _value.held
          // ignore: cast_nullable_to_non_nullable
          : held as bool,
      parent: parent == const $CopyWithPlaceholder()
          ? _value.parent
          // ignore: cast_nullable_to_non_nullable
          : parent as String?,
    );
  }
}

extension $CommentCopyWith on Comment {
  /// Returns a callable class that can be used as follows: `instanceOfComment.copyWith(...)` or like so:`instanceOfComment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommentCWProxy get copyWith => _$CommentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Comment',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'body',
        'created_at',
        'author',
        'like_count',
        'reply_count',
        'liked',
        'mine',
        'pinned',
        'held',
        'parent',
      ],
    );
    final val = Comment(
      id: $checkedConvert('id', (v) => v as String),
      body: $checkedConvert('body', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      author: $checkedConvert(
        'author',
        (v) => CommentAuthor.fromJson(v as Map<String, dynamic>),
      ),
      likeCount: $checkedConvert('like_count', (v) => (v as num).toInt()),
      replyCount: $checkedConvert('reply_count', (v) => (v as num).toInt()),
      liked: $checkedConvert('liked', (v) => v as bool),
      mine: $checkedConvert('mine', (v) => v as bool),
      pinned: $checkedConvert('pinned', (v) => v as bool),
      held: $checkedConvert('held', (v) => v as bool),
      parent: $checkedConvert('parent', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'createdAt': 'created_at',
    'likeCount': 'like_count',
    'replyCount': 'reply_count',
  },
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'id': instance.id,
  'body': instance.body,
  'created_at': instance.createdAt.toIso8601String(),
  'author': instance.author.toJson(),
  'like_count': instance.likeCount,
  'reply_count': instance.replyCount,
  'liked': instance.liked,
  'mine': instance.mine,
  'pinned': instance.pinned,
  'held': instance.held,
  'parent': instance.parent,
};
