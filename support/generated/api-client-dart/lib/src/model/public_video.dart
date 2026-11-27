//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/public_video_kind_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_video.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicVideo {
  /// Returns a new [PublicVideo] instance.
  PublicVideo({
    required this.kind,

    required this.id,

    required this.alt,

    required this.credit,

    required this.width,

    required this.height,

    required this.blurhash,

    required this.color,

    required this.durationMs,

    required this.hls,

    required this.poster,

    required this.sprite,

    required this.spriteVtt,
  });

  @JsonKey(name: r'kind', required: true, includeIfNull: false)
  final PublicVideoKindEnum kind;

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

  @JsonKey(name: r'duration_ms', required: true, includeIfNull: true)
  final int? durationMs;

  @JsonKey(name: r'hls', required: true, includeIfNull: false)
  final String hls;

  @JsonKey(name: r'poster', required: true, includeIfNull: false)
  final String poster;

  @JsonKey(name: r'sprite', required: true, includeIfNull: false)
  final String sprite;

  @JsonKey(name: r'sprite_vtt', required: true, includeIfNull: false)
  final String spriteVtt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicVideo &&
          other.kind == kind &&
          other.id == id &&
          other.alt == alt &&
          other.credit == credit &&
          other.width == width &&
          other.height == height &&
          other.blurhash == blurhash &&
          other.color == color &&
          other.durationMs == durationMs &&
          other.hls == hls &&
          other.poster == poster &&
          other.sprite == sprite &&
          other.spriteVtt == spriteVtt;

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
      (durationMs == null ? 0 : durationMs.hashCode) +
      hls.hashCode +
      poster.hashCode +
      sprite.hashCode +
      spriteVtt.hashCode;

  factory PublicVideo.fromJson(Map<String, dynamic> json) =>
      _$PublicVideoFromJson(json);

  Map<String, dynamic> toJson() => _$PublicVideoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
