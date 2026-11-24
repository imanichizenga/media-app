//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_byline.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CardByline {
  /// Returns a new [CardByline] instance.
  CardByline({
    required this.id,
    required this.name,
    required this.slug,
    required this.path,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'name',
    required: true,
    includeIfNull: false,
  )
  final String name;

  @JsonKey(
    name: r'slug',
    required: true,
    includeIfNull: false,
  )
  final String slug;

  @JsonKey(
    name: r'path',
    required: true,
    includeIfNull: false,
  )
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardByline &&
          other.id == id &&
          other.name == name &&
          other.slug == slug &&
          other.path == path;

  @override
  int get hashCode =>
      id.hashCode + name.hashCode + slug.hashCode + path.hashCode;

  factory CardByline.fromJson(Map<String, dynamic> json) =>
      _$CardBylineFromJson(json);

  Map<String, dynamic> toJson() => _$CardBylineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
