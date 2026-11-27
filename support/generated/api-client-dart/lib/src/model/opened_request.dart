//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'opened_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OpenedRequest {
  /// Returns a new [OpenedRequest] instance.
  OpenedRequest({this.device});

  /// A guest's random id, kept by the browser or app.
  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final String? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenedRequest && other.device == device;

  @override
  int get hashCode => device.hashCode;

  factory OpenedRequest.fromJson(Map<String, dynamic> json) =>
      _$OpenedRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OpenedRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
