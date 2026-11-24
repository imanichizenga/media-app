//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_maintenance.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppMaintenance {
  /// Returns a new [AppMaintenance] instance.
  AppMaintenance({
    required this.on_,
    required this.sw,
    required this.en,
  });

  @JsonKey(
    name: r'on',
    required: true,
    includeIfNull: false,
  )
  final bool on_;

  @JsonKey(
    name: r'sw',
    required: true,
    includeIfNull: false,
  )
  final String sw;

  @JsonKey(
    name: r'en',
    required: true,
    includeIfNull: false,
  )
  final String en;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppMaintenance &&
          other.on_ == on_ &&
          other.sw == sw &&
          other.en == en;

  @override
  int get hashCode => on_.hashCode + sw.hashCode + en.hashCode;

  factory AppMaintenance.fromJson(Map<String, dynamic> json) =>
      _$AppMaintenanceFromJson(json);

  Map<String, dynamic> toJson() => _$AppMaintenanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
