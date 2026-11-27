// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'methods.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MethodsCWProxy {
  Methods phone(bool phone);

  Methods google(bool google);

  Methods googleClientId(String googleClientId);

  Methods apple(bool apple);

  Methods appleServicesId(String appleServicesId);

  Methods countries(List<String> countries);

  Methods codeLength(int codeLength);

  Methods resendSeconds(int resendSeconds);

  Methods termsVersion(String termsVersion);

  Methods localSms(bool localSms);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Methods(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Methods(...).copyWith(id: 12, name: "My name")
  /// ````
  Methods call({
    bool phone,
    bool google,
    String googleClientId,
    bool apple,
    String appleServicesId,
    List<String> countries,
    int codeLength,
    int resendSeconds,
    String termsVersion,
    bool localSms,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMethods.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMethods.copyWith.fieldName(...)`
class _$MethodsCWProxyImpl implements _$MethodsCWProxy {
  const _$MethodsCWProxyImpl(this._value);

  final Methods _value;

  @override
  Methods phone(bool phone) => this(phone: phone);

  @override
  Methods google(bool google) => this(google: google);

  @override
  Methods googleClientId(String googleClientId) =>
      this(googleClientId: googleClientId);

  @override
  Methods apple(bool apple) => this(apple: apple);

  @override
  Methods appleServicesId(String appleServicesId) =>
      this(appleServicesId: appleServicesId);

  @override
  Methods countries(List<String> countries) => this(countries: countries);

  @override
  Methods codeLength(int codeLength) => this(codeLength: codeLength);

  @override
  Methods resendSeconds(int resendSeconds) =>
      this(resendSeconds: resendSeconds);

  @override
  Methods termsVersion(String termsVersion) => this(termsVersion: termsVersion);

  @override
  Methods localSms(bool localSms) => this(localSms: localSms);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Methods(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Methods(...).copyWith(id: 12, name: "My name")
  /// ````
  Methods call({
    Object? phone = const $CopyWithPlaceholder(),
    Object? google = const $CopyWithPlaceholder(),
    Object? googleClientId = const $CopyWithPlaceholder(),
    Object? apple = const $CopyWithPlaceholder(),
    Object? appleServicesId = const $CopyWithPlaceholder(),
    Object? countries = const $CopyWithPlaceholder(),
    Object? codeLength = const $CopyWithPlaceholder(),
    Object? resendSeconds = const $CopyWithPlaceholder(),
    Object? termsVersion = const $CopyWithPlaceholder(),
    Object? localSms = const $CopyWithPlaceholder(),
  }) {
    return Methods(
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as bool,
      google: google == const $CopyWithPlaceholder()
          ? _value.google
          // ignore: cast_nullable_to_non_nullable
          : google as bool,
      googleClientId: googleClientId == const $CopyWithPlaceholder()
          ? _value.googleClientId
          // ignore: cast_nullable_to_non_nullable
          : googleClientId as String,
      apple: apple == const $CopyWithPlaceholder()
          ? _value.apple
          // ignore: cast_nullable_to_non_nullable
          : apple as bool,
      appleServicesId: appleServicesId == const $CopyWithPlaceholder()
          ? _value.appleServicesId
          // ignore: cast_nullable_to_non_nullable
          : appleServicesId as String,
      countries: countries == const $CopyWithPlaceholder()
          ? _value.countries
          // ignore: cast_nullable_to_non_nullable
          : countries as List<String>,
      codeLength: codeLength == const $CopyWithPlaceholder()
          ? _value.codeLength
          // ignore: cast_nullable_to_non_nullable
          : codeLength as int,
      resendSeconds: resendSeconds == const $CopyWithPlaceholder()
          ? _value.resendSeconds
          // ignore: cast_nullable_to_non_nullable
          : resendSeconds as int,
      termsVersion: termsVersion == const $CopyWithPlaceholder()
          ? _value.termsVersion
          // ignore: cast_nullable_to_non_nullable
          : termsVersion as String,
      localSms: localSms == const $CopyWithPlaceholder()
          ? _value.localSms
          // ignore: cast_nullable_to_non_nullable
          : localSms as bool,
    );
  }
}

extension $MethodsCopyWith on Methods {
  /// Returns a callable class that can be used as follows: `instanceOfMethods.copyWith(...)` or like so:`instanceOfMethods.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MethodsCWProxy get copyWith => _$MethodsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Methods _$MethodsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Methods',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'phone',
        'google',
        'google_client_id',
        'apple',
        'apple_services_id',
        'countries',
        'code_length',
        'resend_seconds',
        'terms_version',
        'local_sms',
      ],
    );
    final val = Methods(
      phone: $checkedConvert('phone', (v) => v as bool),
      google: $checkedConvert('google', (v) => v as bool),
      googleClientId: $checkedConvert('google_client_id', (v) => v as String),
      apple: $checkedConvert('apple', (v) => v as bool),
      appleServicesId: $checkedConvert('apple_services_id', (v) => v as String),
      countries: $checkedConvert(
        'countries',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      codeLength: $checkedConvert('code_length', (v) => (v as num).toInt()),
      resendSeconds: $checkedConvert(
        'resend_seconds',
        (v) => (v as num).toInt(),
      ),
      termsVersion: $checkedConvert('terms_version', (v) => v as String),
      localSms: $checkedConvert('local_sms', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'googleClientId': 'google_client_id',
    'appleServicesId': 'apple_services_id',
    'codeLength': 'code_length',
    'resendSeconds': 'resend_seconds',
    'termsVersion': 'terms_version',
    'localSms': 'local_sms',
  },
);

Map<String, dynamic> _$MethodsToJson(Methods instance) => <String, dynamic>{
  'phone': instance.phone,
  'google': instance.google,
  'google_client_id': instance.googleClientId,
  'apple': instance.apple,
  'apple_services_id': instance.appleServicesId,
  'countries': instance.countries,
  'code_length': instance.codeLength,
  'resend_seconds': instance.resendSeconds,
  'terms_version': instance.termsVersion,
  'local_sms': instance.localSms,
};
