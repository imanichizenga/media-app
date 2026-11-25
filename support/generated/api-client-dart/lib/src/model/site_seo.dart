//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_seo.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteSeo {
  /// Returns a new [SiteSeo] instance.
  SiteSeo({
    required this.googleVerification,
    required this.bingVerification,
    required this.indexnowKey,
    required this.sameAs,
  });

  @JsonKey(
    name: r'google_verification',
    required: true,
    includeIfNull: false,
  )
  final String googleVerification;

  @JsonKey(
    name: r'bing_verification',
    required: true,
    includeIfNull: false,
  )
  final String bingVerification;

  @JsonKey(
    name: r'indexnow_key',
    required: true,
    includeIfNull: false,
  )
  final String indexnowKey;

  @JsonKey(
    name: r'same_as',
    required: true,
    includeIfNull: false,
  )
  final List<String> sameAs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteSeo &&
          other.googleVerification == googleVerification &&
          other.bingVerification == bingVerification &&
          other.indexnowKey == indexnowKey &&
          other.sameAs == sameAs;

  @override
  int get hashCode =>
      googleVerification.hashCode +
      bingVerification.hashCode +
      indexnowKey.hashCode +
      sameAs.hashCode;

  factory SiteSeo.fromJson(Map<String, dynamic> json) =>
      _$SiteSeoFromJson(json);

  Map<String, dynamic> toJson() => _$SiteSeoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
