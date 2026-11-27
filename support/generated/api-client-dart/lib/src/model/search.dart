//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/engine_enum.dart';
import 'package:news_api_client/src/model/search_hit.dart';
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
    required this.available,

    required this.query,

    required this.total,

    required this.totalIsExact,

    required this.engine,

    required this.nextCursor,

    required this.results,
  });

  @JsonKey(name: r'available', required: true, includeIfNull: false)
  final bool available;

  @JsonKey(name: r'query', required: true, includeIfNull: false)
  final String query;

  @JsonKey(name: r'total', required: true, includeIfNull: false)
  final int total;

  @JsonKey(name: r'total_is_exact', required: true, includeIfNull: false)
  final bool totalIsExact;

  @JsonKey(name: r'engine', required: true, includeIfNull: false)
  final EngineEnum engine;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<SearchHit> results;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Search &&
          other.available == available &&
          other.query == query &&
          other.total == total &&
          other.totalIsExact == totalIsExact &&
          other.engine == engine &&
          other.nextCursor == nextCursor &&
          other.results == results;

  @override
  int get hashCode =>
      available.hashCode +
      query.hashCode +
      total.hashCode +
      totalIsExact.hashCode +
      engine.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode) +
      results.hashCode;

  factory Search.fromJson(Map<String, dynamic> json) => _$SearchFromJson(json);

  Map<String, dynamic> toJson() => _$SearchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
