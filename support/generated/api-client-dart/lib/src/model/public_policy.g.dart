// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_policy.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicPolicyCWProxy {
  PublicPolicy likes(bool likes);

  PublicPolicy comments(CommentsEnum comments);

  PublicPolicy bookmarks(bool bookmarks);

  PublicPolicy shares(bool shares);

  PublicPolicy reposts(bool reposts);

  PublicPolicy liveChat(bool liveChat);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPolicy(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPolicy(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPolicy call({
    bool likes,
    CommentsEnum comments,
    bool bookmarks,
    bool shares,
    bool reposts,
    bool liveChat,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicPolicy.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicPolicy.copyWith.fieldName(...)`
class _$PublicPolicyCWProxyImpl implements _$PublicPolicyCWProxy {
  const _$PublicPolicyCWProxyImpl(this._value);

  final PublicPolicy _value;

  @override
  PublicPolicy likes(bool likes) => this(likes: likes);

  @override
  PublicPolicy comments(CommentsEnum comments) => this(comments: comments);

  @override
  PublicPolicy bookmarks(bool bookmarks) => this(bookmarks: bookmarks);

  @override
  PublicPolicy shares(bool shares) => this(shares: shares);

  @override
  PublicPolicy reposts(bool reposts) => this(reposts: reposts);

  @override
  PublicPolicy liveChat(bool liveChat) => this(liveChat: liveChat);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPolicy(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPolicy(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPolicy call({
    Object? likes = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? bookmarks = const $CopyWithPlaceholder(),
    Object? shares = const $CopyWithPlaceholder(),
    Object? reposts = const $CopyWithPlaceholder(),
    Object? liveChat = const $CopyWithPlaceholder(),
  }) {
    return PublicPolicy(
      likes: likes == const $CopyWithPlaceholder()
          ? _value.likes
          // ignore: cast_nullable_to_non_nullable
          : likes as bool,
      comments: comments == const $CopyWithPlaceholder()
          ? _value.comments
          // ignore: cast_nullable_to_non_nullable
          : comments as CommentsEnum,
      bookmarks: bookmarks == const $CopyWithPlaceholder()
          ? _value.bookmarks
          // ignore: cast_nullable_to_non_nullable
          : bookmarks as bool,
      shares: shares == const $CopyWithPlaceholder()
          ? _value.shares
          // ignore: cast_nullable_to_non_nullable
          : shares as bool,
      reposts: reposts == const $CopyWithPlaceholder()
          ? _value.reposts
          // ignore: cast_nullable_to_non_nullable
          : reposts as bool,
      liveChat: liveChat == const $CopyWithPlaceholder()
          ? _value.liveChat
          // ignore: cast_nullable_to_non_nullable
          : liveChat as bool,
    );
  }
}

extension $PublicPolicyCopyWith on PublicPolicy {
  /// Returns a callable class that can be used as follows: `instanceOfPublicPolicy.copyWith(...)` or like so:`instanceOfPublicPolicy.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicPolicyCWProxy get copyWith => _$PublicPolicyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPolicy _$PublicPolicyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicPolicy', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'likes',
          'comments',
          'bookmarks',
          'shares',
          'reposts',
          'live_chat',
        ],
      );
      final val = PublicPolicy(
        likes: $checkedConvert('likes', (v) => v as bool),
        comments: $checkedConvert(
          'comments',
          (v) => $enumDecode(_$CommentsEnumEnumMap, v),
        ),
        bookmarks: $checkedConvert('bookmarks', (v) => v as bool),
        shares: $checkedConvert('shares', (v) => v as bool),
        reposts: $checkedConvert('reposts', (v) => v as bool),
        liveChat: $checkedConvert('live_chat', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'liveChat': 'live_chat'});

Map<String, dynamic> _$PublicPolicyToJson(PublicPolicy instance) =>
    <String, dynamic>{
      'likes': instance.likes,
      'comments': _$CommentsEnumEnumMap[instance.comments]!,
      'bookmarks': instance.bookmarks,
      'shares': instance.shares,
      'reposts': instance.reposts,
      'live_chat': instance.liveChat,
    };

const _$CommentsEnumEnumMap = {
  CommentsEnum.open: 'open',
  CommentsEnum.verified: 'verified',
  CommentsEnum.premoderated: 'premoderated',
  CommentsEnum.closed: 'closed',
};
