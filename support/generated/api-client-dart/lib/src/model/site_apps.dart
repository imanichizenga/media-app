//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_apps.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteApps {
  /// Returns a new [SiteApps] instance.
  SiteApps({
    required this.android,
    required this.ios,
  });

  @JsonKey(
    name: r'android',
    required: true,
    includeIfNull: false,
  )
  final String android;

  @JsonKey(
    name: r'ios',
    required: true,
    includeIfNull: false,
  )
  final String ios;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteApps && other.android == android && other.ios == ios;

  @override
  int get hashCode => android.hashCode + ios.hashCode;

  factory SiteApps.fromJson(Map<String, dynamic> json) =>
      _$SiteAppsFromJson(json);

  Map<String, dynamic> toJson() => _$SiteAppsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
