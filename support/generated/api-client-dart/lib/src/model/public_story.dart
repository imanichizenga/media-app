//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_story.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicStory {
  /// Returns a new [PublicStory] instance.
  PublicStory({
    required this.slug,
    required this.title,
    required this.path,
    required this.summary,
    required this.isActive,
  });

  @JsonKey(
    name: r'slug',
    required: true,
    includeIfNull: false,
  )
  final String slug;

  @JsonKey(
    name: r'title',
    required: true,
    includeIfNull: false,
  )
  final String title;

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @JsonKey(
    name: r'summary',
    required: true,
    includeIfNull: false,
  )
  final String summary;

  @JsonKey(
    name: r'is_active',
    required: true,
    includeIfNull: false,
  )
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicStory &&
          other.slug == slug &&
          other.title == title &&
          other.path == path &&
          other.summary == summary &&
          other.isActive == isActive;

  @override
  int get hashCode =>
      slug.hashCode +
      title.hashCode +
      path.hashCode +
      summary.hashCode +
      isActive.hashCode;

  factory PublicStory.fromJson(Map<String, dynamic> json) =>
      _$PublicStoryFromJson(json);

  Map<String, dynamic> toJson() => _$PublicStoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
