//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_identity.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteIdentity {
  /// Returns a new [SiteIdentity] instance.
  SiteIdentity({
    required this.brandName,
    required this.taglineSw,
    required this.taglineEn,
    required this.accentLight,
    required this.accentDark,
  });

  @JsonKey(
    name: r'brand_name',
    required: true,
    includeIfNull: false,
  )
  final String brandName;

  @JsonKey(
    name: r'tagline_sw',
    required: true,
    includeIfNull: false,
  )
  final String taglineSw;

  @JsonKey(
    name: r'tagline_en',
    required: true,
    includeIfNull: false,
  )
  final String taglineEn;

  @JsonKey(
    name: r'accent_light',
    required: true,
    includeIfNull: false,
  )
  final String accentLight;

  @JsonKey(
    name: r'accent_dark',
    required: true,
    includeIfNull: false,
  )
  final String accentDark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteIdentity &&
          other.brandName == brandName &&
          other.taglineSw == taglineSw &&
          other.taglineEn == taglineEn &&
          other.accentLight == accentLight &&
          other.accentDark == accentDark;

  @override
  int get hashCode =>
      brandName.hashCode +
      taglineSw.hashCode +
      taglineEn.hashCode +
      accentLight.hashCode +
      accentDark.hashCode;

  factory SiteIdentity.fromJson(Map<String, dynamic> json) =>
      _$SiteIdentityFromJson(json);

  Map<String, dynamic> toJson() => _$SiteIdentityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
