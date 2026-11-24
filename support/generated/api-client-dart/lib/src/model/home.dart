//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/home_section.dart';
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'home.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Home {
  /// Returns a new [Home] instance.
  Home({
    required this.breaking,
    required this.live,
    required this.lead,
    required this.latest,
    required this.videos,
    required this.shorts,
    required this.sections,
  });

  @JsonKey(
    name: r'breaking',
    required: true,
    includeIfNull: false,
  )
  final List<Card> breaking;

  @JsonKey(
    name: r'live',
    required: true,
    includeIfNull: false,
  )
  final List<Card> live;

  @JsonKey(
    name: r'lead',
    required: true,
    includeIfNull: false,
  )
  final List<Card> lead;

  @JsonKey(
    name: r'latest',
    required: true,
    includeIfNull: false,
  )
  final List<Card> latest;

  @JsonKey(
    name: r'videos',
    required: true,
    includeIfNull: false,
  )
  final List<Card> videos;

  @JsonKey(
    name: r'shorts',
    required: true,
    includeIfNull: false,
  )
  final List<Card> shorts;

  @JsonKey(
    name: r'sections',
    required: true,
    includeIfNull: false,
  )
  final List<HomeSection> sections;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Home &&
          other.breaking == breaking &&
          other.live == live &&
          other.lead == lead &&
          other.latest == latest &&
          other.videos == videos &&
          other.shorts == shorts &&
          other.sections == sections;

  @override
  int get hashCode =>
      breaking.hashCode +
      live.hashCode +
      lead.hashCode +
      latest.hashCode +
      videos.hashCode +
      shorts.hashCode +
      sections.hashCode;

  factory Home.fromJson(Map<String, dynamic> json) => _$HomeFromJson(json);

  Map<String, dynamic> toJson() => _$HomeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
