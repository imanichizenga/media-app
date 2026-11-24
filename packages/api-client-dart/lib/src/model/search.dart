//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Search {
  /// Returns a new [Search] instance.
  Search({
    required this.nextCursor,
    required this.results,
    required this.available,
  });

  @JsonKey(
    name: r'next_cursor',
    required: true,
    includeIfNull: true,
  )
  final String? nextCursor;

  @JsonKey(
    name: r'results',
    required: true,
    includeIfNull: false,
  )
  final List<Card> results;

  @JsonKey(
    name: r'available',
    required: true,
    includeIfNull: false,
  )
  final bool available;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Search &&
          other.nextCursor == nextCursor &&
          other.results == results &&
          other.available == available;

  @override
  int get hashCode =>
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      results.hashCode +
      available.hashCode;

  factory Search.fromJson(Map<String, dynamic> json) => _$SearchFromJson(json);

  Map<String, dynamic> toJson() => _$SearchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
