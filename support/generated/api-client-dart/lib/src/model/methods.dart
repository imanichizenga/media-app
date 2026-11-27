//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'methods.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Methods {
  /// Returns a new [Methods] instance.
  Methods({
    required this.phone,

    required this.google,

    required this.googleClientId,

    required this.apple,

    required this.appleServicesId,

    required this.countries,

    required this.codeLength,

    required this.resendSeconds,

    required this.termsVersion,

    required this.localSms,
  });

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final bool phone;

  @JsonKey(name: r'google', required: true, includeIfNull: false)
  final bool google;

  @JsonKey(name: r'google_client_id', required: true, includeIfNull: false)
  final String googleClientId;

  @JsonKey(name: r'apple', required: true, includeIfNull: false)
  final bool apple;

  @JsonKey(name: r'apple_services_id', required: true, includeIfNull: false)
  final String appleServicesId;

  @JsonKey(name: r'countries', required: true, includeIfNull: false)
  final List<String> countries;

  @JsonKey(name: r'code_length', required: true, includeIfNull: false)
  final int codeLength;

  @JsonKey(name: r'resend_seconds', required: true, includeIfNull: false)
  final int resendSeconds;

  @JsonKey(name: r'terms_version', required: true, includeIfNull: false)
  final String termsVersion;

  /// Development only: the code comes back in the answer, never by SMS.
  @JsonKey(name: r'local_sms', required: true, includeIfNull: false)
  final bool localSms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Methods &&
          other.phone == phone &&
          other.google == google &&
          other.googleClientId == googleClientId &&
          other.apple == apple &&
          other.appleServicesId == appleServicesId &&
          other.countries == countries &&
          other.codeLength == codeLength &&
          other.resendSeconds == resendSeconds &&
          other.termsVersion == termsVersion &&
          other.localSms == localSms;

  @override
  int get hashCode =>
      phone.hashCode +
      google.hashCode +
      googleClientId.hashCode +
      apple.hashCode +
      appleServicesId.hashCode +
      countries.hashCode +
      codeLength.hashCode +
      resendSeconds.hashCode +
      termsVersion.hashCode +
      localSms.hashCode;

  factory Methods.fromJson(Map<String, dynamic> json) =>
      _$MethodsFromJson(json);

  Map<String, dynamic> toJson() => _$MethodsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
