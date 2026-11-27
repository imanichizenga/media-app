//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refresh_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RefreshRequest {
  /// Returns a new [RefreshRequest] instance.
  RefreshRequest({required this.refresh, this.device});

  @JsonKey(name: r'refresh', required: true, includeIfNull: false)
  final String refresh;

  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final String? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefreshRequest &&
          other.refresh == refresh &&
          other.device == device;

  @override
  int get hashCode => refresh.hashCode + device.hashCode;

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
