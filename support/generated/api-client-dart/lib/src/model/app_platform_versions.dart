//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_platform_versions.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppPlatformVersions {
  /// Returns a new [AppPlatformVersions] instance.
  AppPlatformVersions({
    required this.minimum,

    required this.recommended,

    required this.store,
  });

  @JsonKey(name: r'minimum', required: true, includeIfNull: false)
  final String minimum;

  @JsonKey(name: r'recommended', required: true, includeIfNull: false)
  final String recommended;

  @JsonKey(name: r'store', required: true, includeIfNull: false)
  final String store;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPlatformVersions &&
          other.minimum == minimum &&
          other.recommended == recommended &&
          other.store == store;

  @override
  int get hashCode => minimum.hashCode + recommended.hashCode + store.hashCode;

  factory AppPlatformVersions.fromJson(Map<String, dynamic> json) =>
      _$AppPlatformVersionsFromJson(json);

  Map<String, dynamic> toJson() => _$AppPlatformVersionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
