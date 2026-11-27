// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AuthorPageCWProxy {
  AuthorPage nextCursor(String? nextCursor);

  AuthorPage results(List<Card> results);

  AuthorPage author(PublicAuthor author);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AuthorPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AuthorPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AuthorPage call({
    String? nextCursor,
    List<Card> results,
    PublicAuthor author,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfAuthorPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfAuthorPage.copyWith.fieldName(...)`
class _$AuthorPageCWProxyImpl implements _$AuthorPageCWProxy {
  const _$AuthorPageCWProxyImpl(this._value);

  final AuthorPage _value;

  @override
  AuthorPage nextCursor(String? nextCursor) => this(nextCursor: nextCursor);

  @override
  AuthorPage results(List<Card> results) => this(results: results);

  @override
  AuthorPage author(PublicAuthor author) => this(author: author);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `AuthorPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// AuthorPage(...).copyWith(id: 12, name: "My name")
  /// ````
  AuthorPage call({
    Object? nextCursor = const $CopyWithPlaceholder(),
    Object? results = const $CopyWithPlaceholder(),
    Object? author = const $CopyWithPlaceholder(),
  }) {
    return AuthorPage(
      nextCursor: nextCursor == const $CopyWithPlaceholder()
          ? _value.nextCursor
          // ignore: cast_nullable_to_non_nullable
          : nextCursor as String?,
      results: results == const $CopyWithPlaceholder()
          ? _value.results
          // ignore: cast_nullable_to_non_nullable
          : results as List<Card>,
      author: author == const $CopyWithPlaceholder()
          ? _value.author
          // ignore: cast_nullable_to_non_nullable
          : author as PublicAuthor,
    );
  }
}

extension $AuthorPageCopyWith on AuthorPage {
  /// Returns a callable class that can be used as follows: `instanceOfAuthorPage.copyWith(...)` or like so:`instanceOfAuthorPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AuthorPageCWProxy get copyWith => _$AuthorPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthorPage _$AuthorPageFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AuthorPage',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['next_cursor', 'results', 'author']);
    final val = AuthorPage(
      nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
      results: $checkedConvert(
        'results',
        (v) => (v as List<dynamic>)
            .map((e) => Card.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      author: $checkedConvert(
        'author',
        (v) => PublicAuthor.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'nextCursor': 'next_cursor'},
);

Map<String, dynamic> _$AuthorPageToJson(AuthorPage instance) =>
    <String, dynamic>{
      'next_cursor': instance.nextCursor,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'author': instance.author.toJson(),
    };
