// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_request_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodeRequestRequestCWProxy {
  CodeRequestRequest phone(String phone);

  CodeRequestRequest locale(LocaleEnum? locale);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CodeRequestRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CodeRequestRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CodeRequestRequest call({String phone, LocaleEnum? locale});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCodeRequestRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCodeRequestRequest.copyWith.fieldName(...)`
class _$CodeRequestRequestCWProxyImpl implements _$CodeRequestRequestCWProxy {
  const _$CodeRequestRequestCWProxyImpl(this._value);

  final CodeRequestRequest _value;

  @override
  CodeRequestRequest phone(String phone) => this(phone: phone);

  @override
  CodeRequestRequest locale(LocaleEnum? locale) => this(locale: locale);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CodeRequestRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CodeRequestRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CodeRequestRequest call({
    Object? phone = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
  }) {
    return CodeRequestRequest(
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as LocaleEnum?,
    );
  }
}

extension $CodeRequestRequestCopyWith on CodeRequestRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCodeRequestRequest.copyWith(...)` or like so:`instanceOfCodeRequestRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodeRequestRequestCWProxy get copyWith =>
      _$CodeRequestRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodeRequestRequest _$CodeRequestRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CodeRequestRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['phone']);
      final val = CodeRequestRequest(
        phone: $checkedConvert('phone', (v) => v as String),
        locale: $checkedConvert(
          'locale',
          (v) => $enumDecodeNullable(_$LocaleEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CodeRequestRequestToJson(CodeRequestRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'locale': ?_$LocaleEnumEnumMap[instance.locale],
    };

const _$LocaleEnumEnumMap = {LocaleEnum.sw: 'sw', LocaleEnum.en: 'en'};
