//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'related.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Related {
  /// Returns a new [Related] instance.
  Related({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Related && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory Related.fromJson(Map<String, dynamic> json) =>
      _$RelatedFromJson(json);

  Map<String, dynamic> toJson() => _$RelatedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
