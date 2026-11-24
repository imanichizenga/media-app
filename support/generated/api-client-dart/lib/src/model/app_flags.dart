//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_flags.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppFlags {
  /// Returns a new [AppFlags] instance.
  AppFlags({
    required this.shorts,
    required this.youtube,
    required this.offlineSaving,
  });

  @JsonKey(
    name: r'shorts',
    required: true,
    includeIfNull: false,
  )
  final bool shorts;

  @JsonKey(
    name: r'youtube',
    required: true,
    includeIfNull: false,
  )
  final bool youtube;

  @JsonKey(
    name: r'offline_saving',
    required: true,
    includeIfNull: false,
  )
  final bool offlineSaving;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppFlags &&
          other.shorts == shorts &&
          other.youtube == youtube &&
          other.offlineSaving == offlineSaving;

  @override
  int get hashCode =>
      shorts.hashCode + youtube.hashCode + offlineSaving.hashCode;

  factory AppFlags.fromJson(Map<String, dynamic> json) =>
      _$AppFlagsFromJson(json);

  Map<String, dynamic> toJson() => _$AppFlagsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
