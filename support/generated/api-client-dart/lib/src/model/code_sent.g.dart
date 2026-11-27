// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_sent.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodeSentCWProxy {
  CodeSent challenge(String challenge);

  CodeSent phone(String phone);

  CodeSent resendIn(int resendIn);

  CodeSent expiresIn(int expiresIn);

  CodeSent localCode(String? localCode);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CodeSent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CodeSent(...).copyWith(id: 12, name: "My name")
  /// ````
  CodeSent call({
    String challenge,
    String phone,
    int resendIn,
    int expiresIn,
    String? localCode,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCodeSent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCodeSent.copyWith.fieldName(...)`
class _$CodeSentCWProxyImpl implements _$CodeSentCWProxy {
  const _$CodeSentCWProxyImpl(this._value);

  final CodeSent _value;

  @override
  CodeSent challenge(String challenge) => this(challenge: challenge);

  @override
  CodeSent phone(String phone) => this(phone: phone);

  @override
  CodeSent resendIn(int resendIn) => this(resendIn: resendIn);

  @override
  CodeSent expiresIn(int expiresIn) => this(expiresIn: expiresIn);

  @override
  CodeSent localCode(String? localCode) => this(localCode: localCode);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CodeSent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CodeSent(...).copyWith(id: 12, name: "My name")
  /// ````
  CodeSent call({
    Object? challenge = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? resendIn = const $CopyWithPlaceholder(),
    Object? expiresIn = const $CopyWithPlaceholder(),
    Object? localCode = const $CopyWithPlaceholder(),
  }) {
    return CodeSent(
      challenge: challenge == const $CopyWithPlaceholder()
          ? _value.challenge
          // ignore: cast_nullable_to_non_nullable
          : challenge as String,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      resendIn: resendIn == const $CopyWithPlaceholder()
          ? _value.resendIn
          // ignore: cast_nullable_to_non_nullable
          : resendIn as int,
      expiresIn: expiresIn == const $CopyWithPlaceholder()
          ? _value.expiresIn
          // ignore: cast_nullable_to_non_nullable
          : expiresIn as int,
      localCode: localCode == const $CopyWithPlaceholder()
          ? _value.localCode
          // ignore: cast_nullable_to_non_nullable
          : localCode as String?,
    );
  }
}

extension $CodeSentCopyWith on CodeSent {
  /// Returns a callable class that can be used as follows: `instanceOfCodeSent.copyWith(...)` or like so:`instanceOfCodeSent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodeSentCWProxy get copyWith => _$CodeSentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodeSent _$CodeSentFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CodeSent',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['challenge', 'phone', 'resend_in', 'expires_in'],
    );
    final val = CodeSent(
      challenge: $checkedConvert('challenge', (v) => v as String),
      phone: $checkedConvert('phone', (v) => v as String),
      resendIn: $checkedConvert('resend_in', (v) => (v as num).toInt()),
      expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
      localCode: $checkedConvert('local_code', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'resendIn': 'resend_in',
    'expiresIn': 'expires_in',
    'localCode': 'local_code',
  },
);

Map<String, dynamic> _$CodeSentToJson(CodeSent instance) => <String, dynamic>{
  'challenge': instance.challenge,
  'phone': instance.phone,
  'resend_in': instance.resendIn,
  'expires_in': instance.expiresIn,
  'local_code': ?instance.localCode,
};
