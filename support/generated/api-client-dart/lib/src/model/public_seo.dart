//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_seo.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicSeo {
  /// Returns a new [PublicSeo] instance.
  PublicSeo({
    required this.title,
    required this.description,
  });

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'description',
    required: true,
    includeIfNull: false,
  )
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicSeo &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => title.hashCode + description.hashCode;

  factory PublicSeo.fromJson(Map<String, dynamic> json) =>
      _$PublicSeoFromJson(json);

  Map<String, dynamic> toJson() => _$PublicSeoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
