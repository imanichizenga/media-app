//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'translation.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Translation {
  /// Returns a new [Translation] instance.
  Translation({required this.locale, required this.path});

  @JsonKey(name: r'locale', required: true, includeIfNull: false)
  final String locale;

  @JsonKey(name: r'path', required: true, includeIfNull: false)
  final String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Translation && other.locale == locale && other.path == path;

  @override
  int get hashCode => locale.hashCode + path.hashCode;

  factory Translation.fromJson(Map<String, dynamic> json) =>
      _$TranslationFromJson(json);

  Map<String, dynamic> toJson() => _$TranslationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
