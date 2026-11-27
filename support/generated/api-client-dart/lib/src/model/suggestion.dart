//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'suggestion.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Suggestion {
  /// Returns a new [Suggestion] instance.
  Suggestion({
    required this.headline,

    required this.path,

    required this.type,

    required this.category,
  });

  @JsonKey(name: r'headline', required: true, includeIfNull: false)
  final String headline;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @JsonKey(name: r'type', required: true, includeIfNull: false)
  final String type;

  @JsonKey(name: r'category', required: true, includeIfNull: false)
  final String category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          other.headline == headline &&
          other.path == path &&
          other.type == type &&
          other.category == category;

  @override
  int get hashCode =>
      headline.hashCode + path.hashCode + type.hashCode + category.hashCode;

  factory Suggestion.fromJson(Map<String, dynamic> json) =>
      _$SuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$SuggestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
