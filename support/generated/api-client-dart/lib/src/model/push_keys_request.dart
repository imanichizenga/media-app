//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'push_keys_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PushKeysRequest {
  /// Returns a new [PushKeysRequest] instance.
  PushKeysRequest({required this.p256dh, required this.auth});

  @JsonKey(name: r'p256dh', required: true, includeIfNull: false)
  final String p256dh;

  @JsonKey(name: r'auth', required: true, includeIfNull: false)
  final String auth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushKeysRequest && other.p256dh == p256dh && other.auth == auth;

  @override
  int get hashCode => p256dh.hashCode + auth.hashCode;

  factory PushKeysRequest.fromJson(Map<String, dynamic> json) =>
      _$PushKeysRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PushKeysRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
