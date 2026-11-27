//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/reader_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'readers.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Readers {
  /// Returns a new [Readers] instance.
  Readers({
    required this.readers,

    required this.views,

    required this.guests,

    required this.results,

    required this.nextCursor,
  });

  @JsonKey(name: r'readers', required: true, includeIfNull: false)
  final int readers;

  @JsonKey(name: r'views', required: true, includeIfNull: false)
  final int views;

  /// Readers without an account, counted but never named.
  @JsonKey(name: r'guests', required: true, includeIfNull: false)
  final int guests;

  @JsonKey(name: r'results', required: true, includeIfNull: false)
  final List<ReaderEntry> results;

  @JsonKey(name: r'next_cursor', required: true, includeIfNull: true)
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Readers &&
          other.readers == readers &&
          other.views == views &&
          other.guests == guests &&
          other.results == results &&
          other.nextCursor == nextCursor;

  @override
  int get hashCode =>
      readers.hashCode +
      views.hashCode +
      guests.hashCode +
      results.hashCode +
      (nextCursor == null ? 0 : nextCursor.hashCode);

  factory Readers.fromJson(Map<String, dynamic> json) =>
      _$ReadersFromJson(json);

  Map<String, dynamic> toJson() => _$ReadersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
