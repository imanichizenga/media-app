//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/suggestion.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggest.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Suggest {
  /// Returns a new [Suggest] instance.
  Suggest({required this.query, required this.results});

  @JsonKey(name: r'query', required: true, includeIfNull: false)
  final String query;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<Suggestion> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggest && other.query == query && other.results == results;

  @override
  int get hashCode => query.hashCode + results.hashCode;

  factory Suggest.fromJson(Map<String, dynamic> json) =>
      _$SuggestFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
