//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_image_kind_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_image.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicImage {
  /// Returns a new [PublicImage] instance.
  PublicImage({
    required this.kind,

    required this.id,

    required this.alt,

    required this.credit,

    required this.width,

    required this.height,

    required this.blurhash,

    required this.color,

    required this.focal,

    required this.base_,

    required this.widths,

    required this.crops,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final PublicImageKindEnum kind;

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'alt', required: true, includeIfNull: false)
  final String alt;

  @JsonKey(name: r'credit', required: true, includeIfNull: false)
  final String credit;

  @JsonKey(name: r'width', required: true, includeIfNull: true)
  final int? width;

  @JsonKey(name: r'height', required: true, includeIfNull: true)
  final int? height;

  @JsonKey(name: r'blurhash', required: true, includeIfNull: false)
  final String blurhash;

  @JsonKey(name: r'color', required: true, includeIfNull: false)
  final String color;

  @JsonKey(name: r'focal', required: true, includeIfNull: false)
  final List<int> focal;

  @JsonKey(name: r'base', required: true, includeIfNull: false)
  final String base_;

  @JsonKey(name: r'widths', required: true, includeIfNull: false)
  final List<int> widths;

  @JsonKey(name: r'crops', required: true, includeIfNull: false)
  final String crops;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicImage &&
          other.kind == kind &&
          other.id == id &&
          other.alt == alt &&
          other.credit == credit &&
          other.width == width &&
          other.height == height &&
          other.blurhash == blurhash &&
          other.color == color &&
          other.focal == focal &&
          other.base_ == base_ &&
          other.widths == widths &&
          other.crops == crops;

  @override
  int get hashCode =>
      kind.hashCode +
      id.hashCode +
      alt.hashCode +
      credit.hashCode +
      (width == null ? 0 : width.hashCode) +
      (height == null ? 0 : height.hashCode) +
      blurhash.hashCode +
      color.hashCode +
      focal.hashCode +
      base_.hashCode +
      widths.hashCode +
      crops.hashCode;

  factory PublicImage.fromJson(Map<String, dynamic> json) =>
      _$PublicImageFromJson(json);

  Map<String, dynamic> toJson() => _$PublicImageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
