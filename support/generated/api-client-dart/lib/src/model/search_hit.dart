//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/card.dart';
import 'package:news_api_client/src/model/segment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_hit.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchHit {
  /// Returns a new [SearchHit] instance.
  SearchHit({required this.card, required this.snippet});

  @JsonKey(name: r'card', required: true, includeIfNull: false)
  final Card card;

  @JsonKey(name: r'snippet', required: true, includeIfNull: false)
  final List<Segment> snippet;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHit && other.card == card && other.snippet == snippet;

  @override
  int get hashCode => card.hashCode + snippet.hashCode;

  factory SearchHit.fromJson(Map<String, dynamic> json) =>
      _$SearchHitFromJson(json);

  Map<String, dynamic> toJson() => _$SearchHitToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
