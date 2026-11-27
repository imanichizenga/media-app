//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_category_detail.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'category_page.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CategoryPage {
  /// Returns a new [CategoryPage] instance.
  CategoryPage({
    required this.nextCursor,

    required this.results,

    required this.category,
  });

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final PublicCategoryDetail category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryPage &&
          other.nextCursor == nextCursor &&
          other.results == results &&
          other.category == category;

  @override
  int get hashCode =>
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      results.hashCode +
      category.hashCode;

  factory CategoryPage.fromJson(Map<String, dynamic> json) =>
      _$CategoryPageFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
