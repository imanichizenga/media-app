//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'code_verify_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CodeVerifyRequest {
  /// Returns a new [CodeVerifyRequest] instance.
  CodeVerifyRequest({required this.challenge, required this.code, this.device});

  @JsonKey(name: r'challenge', required: true, includeIfNull: false)
  final String challenge;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final String? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeVerifyRequest &&
          other.challenge == challenge &&
          other.code == code &&
          other.device == device;

  @override
  int get hashCode => challenge.hashCode + code.hashCode + device.hashCode;

  factory CodeVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$CodeVerifyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CodeVerifyRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
