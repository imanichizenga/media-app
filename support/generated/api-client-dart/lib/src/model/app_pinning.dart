//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_pinning.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppPinning {
  /// Returns a new [AppPinning] instance.
  AppPinning({
    required this.enabled,
    required this.pins,
  });

  @JsonKey(
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )
  final bool enabled;

  @JsonKey(
    name: r'pins',
    required: true,
    includeIfNull: false,
  )
  final List<String> pins;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPinning && other.enabled == enabled && other.pins == pins;

  @override
  int get hashCode => enabled.hashCode + pins.hashCode;

  factory AppPinning.fromJson(Map<String, dynamic> json) =>
      _$AppPinningFromJson(json);

  Map<String, dynamic> toJson() => _$AppPinningToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
