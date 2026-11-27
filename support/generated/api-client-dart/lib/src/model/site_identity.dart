//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/logo.dart';
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

    required this.wordmarkLight,

    required this.wordmarkDark,

    required this.symbol,
  });

  @JsonKey(name: r'brand_name', required: true, includeIfNull: false)
  final String brandName;

  @JsonKey(name: r'tagline_sw', required: true, includeIfNull: false)
  final String taglineSw;

  @JsonKey(name: r'tagline_en', required: true, includeIfNull: false)
  final String taglineEn;

  @JsonKey(name: r'wordmark_light', required: true, includeIfNull: true)
  final Logo? wordmarkLight;

  @JsonKey(name: r'wordmark_dark', required: true, includeIfNull: true)
  final Logo? wordmarkDark;

  @JsonKey(name: r'symbol', required: true, includeIfNull: true)
  final Logo? symbol;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteIdentity &&
          other.brandName == brandName &&
          other.taglineSw == taglineSw &&
          other.taglineEn == taglineEn &&
          other.wordmarkLight == wordmarkLight &&
          other.wordmarkDark == wordmarkDark &&
          other.symbol == symbol;

  @override
  int get hashCode =>
      brandName.hashCode +
      taglineSw.hashCode +
      taglineEn.hashCode +
      (wordmarkLight == null ? 0 : wordmarkLight.hashCode) +
      (wordmarkDark == null ? 0 : wordmarkDark.hashCode) +
      (symbol == null ? 0 : symbol.hashCode);

  factory SiteIdentity.fromJson(Map<String, dynamic> json) =>
      _$SiteIdentityFromJson(json);

  Map<String, dynamic> toJson() => _$SiteIdentityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
