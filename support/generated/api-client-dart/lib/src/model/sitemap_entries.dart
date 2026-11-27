//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/sitemap_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sitemap_entries.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SitemapEntries {
  /// Returns a new [SitemapEntries] instance.
  SitemapEntries({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<SitemapEntry> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SitemapEntries && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory SitemapEntries.fromJson(Map<String, dynamic> json) =>
      _$SitemapEntriesFromJson(json);

  Map<String, dynamic> toJson() => _$SitemapEntriesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
