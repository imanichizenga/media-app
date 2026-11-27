//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'segment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Segment {
  /// Returns a new [Segment] instance.
  Segment({required this.text, required this.hit});

  @JsonKey(name: r'text', required: true, includeIfNull: false)
  final String text;

  @JsonKey(name: r'hit', required: true, includeIfNull: false)
  final bool hit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Segment && other.text == text && other.hit == hit;

  @override
  int get hashCode => text.hashCode + hit.hashCode;

  factory Segment.fromJson(Map<String, dynamic> json) =>
      _$SegmentFromJson(json);

  Map<String, dynamic> toJson() => _$SegmentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
