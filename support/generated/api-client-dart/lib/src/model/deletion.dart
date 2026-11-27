//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deletion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Deletion {
  /// Returns a new [Deletion] instance.
  Deletion({required this.graceDays});

  @JsonKey(name: r'grace_days', required: true, includeIfNull: false)
  final int graceDays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deletion && other.graceDays == graceDays;

  @override
  int get hashCode => graceDays.hashCode;

  factory Deletion.fromJson(Map<String, dynamic> json) =>
      _$DeletionFromJson(json);

  Map<String, dynamic> toJson() => _$DeletionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
