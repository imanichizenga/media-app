//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_category.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home_section.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HomeSection {
  /// Returns a new [HomeSection] instance.
  HomeSection({required this.category, required this.results});

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final PublicCategory category;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeSection &&
          other.category == category &&
          other.results == results;

  @override
  int get hashCode => category.hashCode + results.hashCode;

  factory HomeSection.fromJson(Map<String, dynamic> json) =>
      _$HomeSectionFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
