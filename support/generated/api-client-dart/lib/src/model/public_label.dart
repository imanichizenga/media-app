//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_label.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicLabel {
  /// Returns a new [PublicLabel] instance.
  PublicLabel({required this.slug, required this.name, required this.path});

  @JsonKey(name: r'slug', required: true, includeIfNull: false)
  final String slug;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicLabel &&
          other.slug == slug &&
          other.name == name &&
          other.path == path;

  @override
  int get hashCode => slug.hashCode + name.hashCode + path.hashCode;

  factory PublicLabel.fromJson(Map<String, dynamic> json) =>
      _$PublicLabelFromJson(json);

  Map<String, dynamic> toJson() => _$PublicLabelToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
