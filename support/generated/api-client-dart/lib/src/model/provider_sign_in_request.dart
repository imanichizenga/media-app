//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provider_sign_in_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderSignInRequest {
  /// Returns a new [ProviderSignInRequest] instance.
  ProviderSignInRequest({
    this.idToken,

    this.code,

    this.redirectUri,

    this.codeVerifier,

    this.nonce,

    this.name,

    this.device,
  });

  /// From the app's SDK.
  @JsonKey(name: r'id_token', required: false, includeIfNull: false)
  final String? idToken;

  /// From the website's redirect.
  @JsonKey(name: r'code', required: false, includeIfNull: false)
  final String? code;

  @JsonKey(name: r'redirect_uri', required: false, includeIfNull: false)
  final String? redirectUri;

  @JsonKey(name: r'code_verifier', required: false, includeIfNull: false)
  final String? codeVerifier;

  @JsonKey(name: r'nonce', required: false, includeIfNull: false)
  final String? nonce;

  /// Apple sends the name once, outside the token.
  @JsonKey(name: r'name', required: false, includeIfNull: false)
  final String? name;

  @JsonKey(name: r'device', required: false, includeIfNull: false)
  final String? device;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderSignInRequest &&
          other.idToken == idToken &&
          other.code == code &&
          other.redirectUri == redirectUri &&
          other.codeVerifier == codeVerifier &&
          other.nonce == nonce &&
          other.name == name &&
          other.device == device;

  @override
  int get hashCode =>
      idToken.hashCode +
      code.hashCode +
      redirectUri.hashCode +
      codeVerifier.hashCode +
      nonce.hashCode +
      name.hashCode +
      device.hashCode;

  factory ProviderSignInRequest.fromJson(Map<String, dynamic> json) =>
      _$ProviderSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderSignInRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
