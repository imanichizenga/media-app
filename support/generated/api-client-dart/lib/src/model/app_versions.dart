//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/app_platform_versions.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_versions.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppVersions {
  /// Returns a new [AppVersions] instance.
  AppVersions({
    required this.android,
    required this.ios,
  });

  @JsonKey(
    name: r'android',
    required: true,
    includeIfNull: false,
  )
  final AppPlatformVersions android;

  @JsonKey(
    name: r'ios',
    required: true,
    includeIfNull: false,
  )
  final AppPlatformVersions ios;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppVersions && other.android == android && other.ios == ios;

  @override
  int get hashCode => android.hashCode + ios.hashCode;

  factory AppVersions.fromJson(Map<String, dynamic> json) =>
      _$AppVersionsFromJson(json);

  Map<String, dynamic> toJson() => _$AppVersionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
