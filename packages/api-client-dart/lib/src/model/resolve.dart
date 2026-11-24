//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'resolve.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Resolve {
  /// Returns a new [Resolve] instance.
  Resolve({
    required this.path,
  });

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Resolve && other.path == path;

  @override
  int get hashCode => path.hashCode;

  factory Resolve.fromJson(Map<String, dynamic> json) =>
      _$ResolveFromJson(json);

  Map<String, dynamic> toJson() => _$ResolveToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
