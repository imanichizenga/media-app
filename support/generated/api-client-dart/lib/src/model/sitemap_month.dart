//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sitemap_month.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SitemapMonth {
  /// Returns a new [SitemapMonth] instance.
  SitemapMonth({
    required this.month,
    required this.count,
    required this.modifiedAt,
    required this.videos,
  });

  @JsonKey(
    name: r'month',
    required: true,
    includeIfNull: false,
  )
  final String month;

  @JsonKey(
    name: r'count',
    required: true,
    includeIfNull: false,
  )
  final int count;

  @JsonKey(
    name: r'modified_at',
    required: true,
    includeIfNull: false,
  )
  final DateTime modifiedAt;

  @JsonKey(
    name: r'videos',
    required: true,
    includeIfNull: false,
  )
  final int videos;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SitemapMonth &&
          other.month == month &&
          other.count == count &&
          other.modifiedAt == modifiedAt &&
          other.videos == videos;

  @override
  int get hashCode =>
      month.hashCode + count.hashCode + modifiedAt.hashCode + videos.hashCode;

  factory SitemapMonth.fromJson(Map<String, dynamic> json) =>
      _$SitemapMonthFromJson(json);

  Map<String, dynamic> toJson() => _$SitemapMonthToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
