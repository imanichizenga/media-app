// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommentPageCWProxy {
  CommentPage policy(PublicPolicy policy);

  CommentPage count(int count);

  CommentPage results(List<Comment> results);

  CommentPage nextCursor(String? nextCursor);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommentPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommentPage(...).copyWith(id: 12, name: "My name")
  /// ````
  CommentPage call({
    PublicPolicy policy,
    int count,
    List<Comment> results,
    String? nextCursor,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCommentPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCommentPage.copyWith.fieldName(...)`
class _$CommentPageCWProxyImpl implements _$CommentPageCWProxy {
  const _$CommentPageCWProxyImpl(this._value);

  final CommentPage _value;

  @override
  CommentPage policy(PublicPolicy policy) => this(policy: policy);

  @override
  CommentPage count(int count) => this(count: count);

  @override
  CommentPage results(List<Comment> results) => this(results: results);

  @override
  CommentPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommentPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommentPage(...).copyWith(id: 12, name: "My name")
  /// ````
  CommentPage call({
    Object? policy = const $CopyWithPlaceholder(),
    Object? count = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? nextCursor = const $CopyWithPlaceholder(),
  }) {
    return CommentPage(
      policy: policy == const $CopyWithPlaceholder()
          ? _value.policy
          // ignore: cast_nullable_to_non_nullable
          : policy as PublicPolicy,
      count: count == const $CopyWithPlaceholder()
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Comment>,
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
    );
  }
}

extension $CommentPageCopyWith on CommentPage {
  /// Returns a callable class that can be used as follows: `instanceOfCommentPage.copyWith(...)` or like so:`instanceOfCommentPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommentPageCWProxy get copyWith => _$CommentPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentPage _$CommentPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommentPage', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['policy', 'count', 'results', 'next_cursor'],
      );
      final val = CommentPage(
        policy: $checkedConvert(
          'policy',
          (v) => PublicPolicy.fromJson(v as Map<String, dynamic>),
        ),
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        results: $checkedConvert(
          'results',
          (v) => (v as List<dynamic>)
              .map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'nextCursor': 'next_cursor'});

Map<String, dynamic> _$CommentPageToJson(CommentPage instance) =>
    <String, dynamic>{
      'policy': instance.policy.toJson(),
      'count': instance.count,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'next_cursor': instance.nextCursor,
    };
