//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_story_ref.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicStoryRef {
  /// Returns a new [PublicStoryRef] instance.
  PublicStoryRef({required this.slug, required this.title, required this.path});

  @JsonKey(name: r'slug', required: true, includeIfNull: false)
  final String slug;

  @JsonKey(name: r'title', required: true, includeIfNull: false)
  final String title;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicStoryRef &&
          other.slug == slug &&
          other.title == title &&
          other.path == path;

  @override
  int get hashCode => slug.hashCode + title.hashCode + path.hashCode;

  factory PublicStoryRef.fromJson(Map<String, dynamic> json) =>
      _$PublicStoryRefFromJson(json);

  Map<String, dynamic> toJson() => _$PublicStoryRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
