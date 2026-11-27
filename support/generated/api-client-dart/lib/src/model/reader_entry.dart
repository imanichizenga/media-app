//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reader_entry.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReaderEntry {
  /// Returns a new [ReaderEntry] instance.
  ReaderEntry({
    required this.name,

    required this.username,

    required this.initial,

    required this.at,
  });

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'username', required: true, includeIfNull: false)
  final String username;

  @JsonKey(name: r'initial', required: true, includeIfNull: false)
  final String initial;

  @JsonKey(name: r'at', required: true, includeIfNull: false)
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderEntry &&
          other.name == name &&
          other.username == username &&
          other.initial == initial &&
          other.at == at;

  @override
  int get hashCode =>
      name.hashCode + username.hashCode + initial.hashCode + at.hashCode;

  factory ReaderEntry.fromJson(Map<String, dynamic> json) =>
      _$ReaderEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ReaderEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
