//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schemes.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Schemes {
  /// Returns a new [Schemes] instance.
  Schemes({
    required this.light,
    required this.dark,
  });

  @JsonKey(
    name: r'light',
    required: true,
    includeIfNull: false,
  )
  final String light;

  @JsonKey(
    name: r'dark',
    required: true,
    includeIfNull: false,
  )
  final String dark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schemes && other.light == light && other.dark == dark;

  @override
  int get hashCode => light.hashCode + dark.hashCode;

  factory Schemes.fromJson(Map<String, dynamic> json) =>
      _$SchemesFromJson(json);

  Map<String, dynamic> toJson() => _$SchemesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
