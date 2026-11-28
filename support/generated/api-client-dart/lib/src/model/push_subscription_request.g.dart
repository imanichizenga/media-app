// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_subscription_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PushSubscriptionRequestCWProxy {
  PushSubscriptionRequest endpoint(String endpoint);

  PushSubscriptionRequest keys(PushKeysRequest keys);

  PushSubscriptionRequest locale(LocaleEnum? locale);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PushSubscriptionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PushSubscriptionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PushSubscriptionRequest call({
    String endpoint,
    PushKeysRequest keys,
    LocaleEnum? locale,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPushSubscriptionRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPushSubscriptionRequest.copyWith.fieldName(...)`
class _$PushSubscriptionRequestCWProxyImpl
    implements _$PushSubscriptionRequestCWProxy {
  const _$PushSubscriptionRequestCWProxyImpl(this._value);

  final PushSubscriptionRequest _value;

  @override
  PushSubscriptionRequest endpoint(String endpoint) => this(endpoint: endpoint);

  @override
  PushSubscriptionRequest keys(PushKeysRequest keys) => this(keys: keys);

  @override
  PushSubscriptionRequest locale(LocaleEnum? locale) => this(locale: locale);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PushSubscriptionRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PushSubscriptionRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PushSubscriptionRequest call({
    Object? endpoint = const $CopyWithPlaceholder(),
    Object? keys = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
  }) {
    return PushSubscriptionRequest(
      endpoint: endpoint == const $CopyWithPlaceholder()
          ? _value.endpoint
          // ignore: cast_nullable_to_non_nullable
          : endpoint as String,
      keys: keys == const $CopyWithPlaceholder()
          ? _value.keys
          // ignore: cast_nullable_to_non_nullable
          : keys as PushKeysRequest,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as LocaleEnum?,
    );
  }
}

extension $PushSubscriptionRequestCopyWith on PushSubscriptionRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPushSubscriptionRequest.copyWith(...)` or like so:`instanceOfPushSubscriptionRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PushSubscriptionRequestCWProxy get copyWith =>
      _$PushSubscriptionRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushSubscriptionRequest _$PushSubscriptionRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PushSubscriptionRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['endpoint', 'keys']);
  final val = PushSubscriptionRequest(
    endpoint: $checkedConvert('endpoint', (v) => v as String),
    keys: $checkedConvert(
      'keys',
      (v) => PushKeysRequest.fromJson(v as Map<String, dynamic>),
    ),
    locale: $checkedConvert(
      'locale',
      (v) => $enumDecodeNullable(_$LocaleEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$PushSubscriptionRequestToJson(
  PushSubscriptionRequest instance,
) => <String, dynamic>{
  'endpoint': instance.endpoint,
  'keys': instance.keys.toJson(),
  'locale': ?_$LocaleEnumEnumMap[instance.locale],
};

const _$LocaleEnumEnumMap = {LocaleEnum.sw: 'sw', LocaleEnum.en: 'en'};
