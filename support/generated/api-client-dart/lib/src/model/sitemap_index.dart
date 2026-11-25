//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/sitemap_month.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sitemap_index.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SitemapIndex {
  /// Returns a new [SitemapIndex] instance.
  SitemapIndex({
    required this.months,
  });

  @JsonKey(
    name: r'months',
    required: true,
    includeIfNull: false,
  )
  final List<SitemapMonth> months;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SitemapIndex && other.months == months;

  @override
  int get hashCode => months.hashCode;

  factory SitemapIndex.fromJson(Map<String, dynamic> json) =>
      _$SitemapIndexFromJson(json);

  Map<String, dynamic> toJson() => _$SitemapIndexToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
