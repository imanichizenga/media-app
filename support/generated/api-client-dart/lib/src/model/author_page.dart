//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_author.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'author_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthorPage {
  /// Returns a new [AuthorPage] instance.
  AuthorPage({
    required this.nextCursor,
    required this.results,
    required this.author,
  });

  @JsonKey(
    name: r'next_cursor',
    required: true,
    includeIfNull: true,
  )
  final String? nextCursor;

  @JsonKey(
    name: r'results',
    required: true,
    includeIfNull: false,
  )
  final List<Card> results;

  @JsonKey(
    name: r'author',
    required: true,
    includeIfNull: false,
  )
  final PublicAuthor author;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorPage &&
          other.nextCursor == nextCursor &&
          other.results == results &&
          other.author == author;

  @override
  int get hashCode =>
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      results.hashCode +
      author.hashCode;

  factory AuthorPage.fromJson(Map<String, dynamic> json) =>
      _$AuthorPageFromJson(json);

  Map<String, dynamic> toJson() => _$AuthorPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
