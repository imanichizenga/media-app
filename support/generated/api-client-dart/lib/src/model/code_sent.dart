//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'code_sent.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CodeSent {
  /// Returns a new [CodeSent] instance.
  CodeSent({
    required this.challenge,

    required this.phone,

    required this.resendIn,

    required this.expiresIn,

    this.localCode,
  });

  @JsonKey(name: r'challenge', required: true, includeIfNull: false)
  final String challenge;

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'resend_in', required: true, includeIfNull: false)
  final int resendIn;

  @JsonKey(name: r'expires_in', required: true, includeIfNull: false)
  final int expiresIn;

  @JsonKey(name: r'local_code', required: false, includeIfNull: false)
  final String? localCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeSent &&
          other.challenge == challenge &&
          other.phone == phone &&
          other.resendIn == resendIn &&
          other.expiresIn == expiresIn &&
          other.localCode == localCode;

  @override
  int get hashCode =>
      challenge.hashCode +
      phone.hashCode +
      resendIn.hashCode +
      expiresIn.hashCode +
      localCode.hashCode;

  factory CodeSent.fromJson(Map<String, dynamic> json) =>
      _$CodeSentFromJson(json);

  Map<String, dynamic> toJson() => _$CodeSentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
