// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_verify_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodeVerifyRequestCWProxy {
  CodeVerifyRequest challenge(String challenge);

  CodeVerifyRequest code(String code);

  CodeVerifyRequest device(String? device);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CodeVerifyRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CodeVerifyRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CodeVerifyRequest call({String challenge, String code, String? device});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCodeVerifyRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCodeVerifyRequest.copyWith.fieldName(...)`
class _$CodeVerifyRequestCWProxyImpl implements _$CodeVerifyRequestCWProxy {
  const _$CodeVerifyRequestCWProxyImpl(this._value);

  final CodeVerifyRequest _value;

  @override
  CodeVerifyRequest challenge(String challenge) => this(challenge: challenge);

  @override
  CodeVerifyRequest code(String code) => this(code: code);

  @override
  CodeVerifyRequest device(String? device) => this(device: device);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CodeVerifyRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CodeVerifyRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CodeVerifyRequest call({
    Object? challenge = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? device = const $CopyWithPlaceholder(),
  }) {
    return CodeVerifyRequest(
      challenge: challenge == const $CopyWithPlaceholder()
          ? _value.challenge
          // ignore: cast_nullable_to_non_nullable
          : challenge as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      device: device == const $CopyWithPlaceholder()
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as String?,
    );
  }
}

extension $CodeVerifyRequestCopyWith on CodeVerifyRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCodeVerifyRequest.copyWith(...)` or like so:`instanceOfCodeVerifyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodeVerifyRequestCWProxy get copyWith =>
      _$CodeVerifyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodeVerifyRequest _$CodeVerifyRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CodeVerifyRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['challenge', 'code']);
      final val = CodeVerifyRequest(
        challenge: $checkedConvert('challenge', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        device: $checkedConvert('device', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$CodeVerifyRequestToJson(CodeVerifyRequest instance) =>
    <String, dynamic>{
      'challenge': instance.challenge,
      'code': instance.code,
      'device': ?instance.device,
    };
