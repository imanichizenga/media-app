// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_comment_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NewCommentRequestCWProxy {
  NewCommentRequest body(String body);

  NewCommentRequest parent(String? parent);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NewCommentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NewCommentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  NewCommentRequest call({String body, String? parent});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfNewCommentRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfNewCommentRequest.copyWith.fieldName(...)`
class _$NewCommentRequestCWProxyImpl implements _$NewCommentRequestCWProxy {
  const _$NewCommentRequestCWProxyImpl(this._value);

  final NewCommentRequest _value;

  @override
  NewCommentRequest body(String body) => this(body: body);

  @override
  NewCommentRequest parent(String? parent) => this(parent: parent);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `NewCommentRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// NewCommentRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  NewCommentRequest call({
    Object? body = const $CopyWithPlaceholder(),
    Object? parent = const $CopyWithPlaceholder(),
  }) {
    return NewCommentRequest(
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as String,
      parent: parent == const $CopyWithPlaceholder()
          ? _value.parent
          // ignore: cast_nullable_to_non_nullable
          : parent as String?,
    );
  }
}

extension $NewCommentRequestCopyWith on NewCommentRequest {
  /// Returns a callable class that can be used as follows: `instanceOfNewCommentRequest.copyWith(...)` or like so:`instanceOfNewCommentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NewCommentRequestCWProxy get copyWith =>
      _$NewCommentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewCommentRequest _$NewCommentRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NewCommentRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['body']);
      final val = NewCommentRequest(
        body: $checkedConvert('body', (v) => v as String),
        parent: $checkedConvert('parent', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$NewCommentRequestToJson(NewCommentRequest instance) =>
    <String, dynamic>{'body': instance.body, 'parent': ?instance.parent};
