//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'related_target.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RelatedTarget {
  /// Returns a new [RelatedTarget] instance.
  RelatedTarget({
    required this.path,
    required this.headline,
  });

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @JsonKey(
    name: r'headline',
    required: true,
    includeIfNull: false,
  )
  final String headline;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelatedTarget &&
          other.path == path &&
          other.headline == headline;

  @override
  int get hashCode => path.hashCode + headline.hashCode;

  factory RelatedTarget.fromJson(Map<String, dynamic> json) =>
      _$RelatedTargetFromJson(json);

  Map<String, dynamic> toJson() => _$RelatedTargetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
