// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_author.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommentAuthorCWProxy {
  CommentAuthor name(String name);

  CommentAuthor username(String username);

  CommentAuthor initial(String initial);

  CommentAuthor isWriter(bool isWriter);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommentAuthor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommentAuthor(...).copyWith(id: 12, name: "My name")
  /// ````
  CommentAuthor call({
    String name,
    String username,
    String initial,
    bool isWriter,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCommentAuthor.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCommentAuthor.copyWith.fieldName(...)`
class _$CommentAuthorCWProxyImpl implements _$CommentAuthorCWProxy {
  const _$CommentAuthorCWProxyImpl(this._value);

  final CommentAuthor _value;

  @override
  CommentAuthor name(String name) => this(name: name);

  @override
  CommentAuthor username(String username) => this(username: username);

  @override
  CommentAuthor initial(String initial) => this(initial: initial);

  @override
  CommentAuthor isWriter(bool isWriter) => this(isWriter: isWriter);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CommentAuthor(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CommentAuthor(...).copyWith(id: 12, name: "My name")
  /// ````
  CommentAuthor call({
    Object? name = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? initial = const $CopyWithPlaceholder(),
    Object? isWriter = const $CopyWithPlaceholder(),
  }) {
    return CommentAuthor(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      initial: initial == const $CopyWithPlaceholder()
          ? _value.initial
          // ignore: cast_nullable_to_non_nullable
          : initial as String,
      isWriter: isWriter == const $CopyWithPlaceholder()
          ? _value.isWriter
          // ignore: cast_nullable_to_non_nullable
          : isWriter as bool,
    );
  }
}

extension $CommentAuthorCopyWith on CommentAuthor {
  /// Returns a callable class that can be used as follows: `instanceOfCommentAuthor.copyWith(...)` or like so:`instanceOfCommentAuthor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommentAuthorCWProxy get copyWith => _$CommentAuthorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommentAuthor _$CommentAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommentAuthor', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['name', 'username', 'initial', 'is_writer'],
      );
      final val = CommentAuthor(
        name: $checkedConvert('name', (v) => v as String),
        username: $checkedConvert('username', (v) => v as String),
        initial: $checkedConvert('initial', (v) => v as String),
        isWriter: $checkedConvert('is_writer', (v) => v as bool),
      );
      return val;
    }, fieldKeyMap: const {'isWriter': 'is_writer'});

Map<String, dynamic> _$CommentAuthorToJson(CommentAuthor instance) =>
    <String, dynamic>{
      'name': instance.name,
      'username': instance.username,
      'initial': instance.initial,
      'is_writer': instance.isWriter,
    };
