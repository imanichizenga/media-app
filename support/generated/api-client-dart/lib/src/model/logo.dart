//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'logo.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Logo {
  /// Returns a new [Logo] instance.
  Logo({
    required this.id,
    required this.width,
    required this.height,
    required this.derived,
    required this.svg,
    required this.png,
  });

  @JsonKey(
    name: r'id',
    required: true,
    includeIfNull: false,
  )
  final String id;

  @JsonKey(
    name: r'width',
    required: true,
    includeIfNull: false,
  )
  final int width;

  @JsonKey(
    name: r'height',
    required: true,
    includeIfNull: false,
  )
  final int height;

  @JsonKey(
    name: r'derived',
    required: true,
    includeIfNull: false,
  )
  final bool derived;

  @JsonKey(
    name: r'svg',
    required: true,
    includeIfNull: false,
  )
  final String svg;

  @JsonKey(
    name: r'png',
    required: true,
    includeIfNull: false,
  )
  final Map<String, String> png;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Logo &&
          other.id == id &&
          other.width == width &&
          other.height == height &&
          other.derived == derived &&
          other.svg == svg &&
          other.png == png;

  @override
  int get hashCode =>
      id.hashCode +
      width.hashCode +
      height.hashCode +
      derived.hashCode +
      svg.hashCode +
      png.hashCode;

  factory Logo.fromJson(Map<String, dynamic> json) => _$LogoFromJson(json);

  Map<String, dynamic> toJson() => _$LogoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
