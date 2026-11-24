//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_region.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicRegion {
  /// Returns a new [PublicRegion] instance.
  PublicRegion({
    required this.slug,
    required this.name,
  });

  @JsonKey(
    name: r'slug',
    required: true,
    includeIfNull: false,
  )
  final String slug;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicRegion && other.slug == slug && other.name == name;

  @override
  int get hashCode => slug.hashCode + name.hashCode;

  factory PublicRegion.fromJson(Map<String, dynamic> json) =>
      _$PublicRegionFromJson(json);

  Map<String, dynamic> toJson() => _$PublicRegionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
