//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_list.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CardList {
  /// Returns a new [CardList] instance.
  CardList({required this.results});

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Card> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CardList && other.results == results;

  @override
  int get hashCode => results.hashCode;

  factory CardList.fromJson(Map<String, dynamic> json) =>
      _$CardListFromJson(json);

  Map<String, dynamic> toJson() => _$CardListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
