// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_sign_in_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProviderSignInRequestCWProxy {
  ProviderSignInRequest idToken(String? idToken);

  ProviderSignInRequest code(String? code);

  ProviderSignInRequest redirectUri(String? redirectUri);

  ProviderSignInRequest codeVerifier(String? codeVerifier);

  ProviderSignInRequest nonce(String? nonce);

  ProviderSignInRequest name(String? name);

  ProviderSignInRequest device(String? device);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProviderSignInRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProviderSignInRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ProviderSignInRequest call({
    String? idToken,
    String? code,
    String? redirectUri,
    String? codeVerifier,
    String? nonce,
    String? name,
    String? device,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfProviderSignInRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfProviderSignInRequest.copyWith.fieldName(...)`
class _$ProviderSignInRequestCWProxyImpl
    implements _$ProviderSignInRequestCWProxy {
  const _$ProviderSignInRequestCWProxyImpl(this._value);

  final ProviderSignInRequest _value;

  @override
  ProviderSignInRequest idToken(String? idToken) => this(idToken: idToken);

  @override
  ProviderSignInRequest code(String? code) => this(code: code);

  @override
  ProviderSignInRequest redirectUri(String? redirectUri) =>
      this(redirectUri: redirectUri);

  @override
  ProviderSignInRequest codeVerifier(String? codeVerifier) =>
      this(codeVerifier: codeVerifier);

  @override
  ProviderSignInRequest nonce(String? nonce) => this(nonce: nonce);

  @override
  ProviderSignInRequest name(String? name) => this(name: name);

  @override
  ProviderSignInRequest device(String? device) => this(device: device);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ProviderSignInRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ProviderSignInRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  ProviderSignInRequest call({
    Object? idToken = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? redirectUri = const $CopyWithPlaceholder(),
    Object? codeVerifier = const $CopyWithPlaceholder(),
    Object? nonce = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? device = const $CopyWithPlaceholder(),
  }) {
    return ProviderSignInRequest(
      idToken: idToken == const $CopyWithPlaceholder()
          ? _value.idToken
          // ignore: cast_nullable_to_non_nullable
          : idToken as String?,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String?,
      redirectUri: redirectUri == const $CopyWithPlaceholder()
          ? _value.redirectUri
          // ignore: cast_nullable_to_non_nullable
          : redirectUri as String?,
      codeVerifier: codeVerifier == const $CopyWithPlaceholder()
          ? _value.codeVerifier
          // ignore: cast_nullable_to_non_nullable
          : codeVerifier as String?,
      nonce: nonce == const $CopyWithPlaceholder()
          ? _value.nonce
          // ignore: cast_nullable_to_non_nullable
          : nonce as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      device: device == const $CopyWithPlaceholder()
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as String?,
    );
  }
}

extension $ProviderSignInRequestCopyWith on ProviderSignInRequest {
  /// Returns a callable class that can be used as follows: `instanceOfProviderSignInRequest.copyWith(...)` or like so:`instanceOfProviderSignInRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProviderSignInRequestCWProxy get copyWith =>
      _$ProviderSignInRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProviderSignInRequest _$ProviderSignInRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ProviderSignInRequest',
  json,
  ($checkedConvert) {
    final val = ProviderSignInRequest(
      idToken: $checkedConvert('id_token', (v) => v as String?),
      code: $checkedConvert('code', (v) => v as String?),
      redirectUri: $checkedConvert('redirect_uri', (v) => v as String?),
      codeVerifier: $checkedConvert('code_verifier', (v) => v as String?),
      nonce: $checkedConvert('nonce', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String?),
      device: $checkedConvert('device', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'idToken': 'id_token',
    'redirectUri': 'redirect_uri',
    'codeVerifier': 'code_verifier',
  },
);

Map<String, dynamic> _$ProviderSignInRequestToJson(
  ProviderSignInRequest instance,
) => <String, dynamic>{
  'id_token': ?instance.idToken,
  'code': ?instance.code,
  'redirect_uri': ?instance.redirectUri,
  'code_verifier': ?instance.codeVerifier,
  'nonce': ?instance.nonce,
  'name': ?instance.name,
  'device': ?instance.device,
};
