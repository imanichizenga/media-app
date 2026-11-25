//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_page_link.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_pages.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicPages {
  /// Returns a new [PublicPages] instance.
  PublicPages({
    required this.results,
  });

  @JsonKey(
    name: r'results',
    required: true,
    includeIfNull: false,
  )
  final List<PublicPageLink> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicPages && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory PublicPages.fromJson(Map<String, dynamic> json) =>
      _$PublicPagesFromJson(json);

  Map<String, dynamic> toJson() => _$PublicPagesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
