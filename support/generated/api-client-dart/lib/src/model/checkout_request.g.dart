// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckoutRequestCWProxy {
  CheckoutRequest plan(String plan);

  CheckoutRequest method(PaymentMethodEnum method);

  CheckoutRequest phone(String? phone);

  CheckoutRequest returnPath(String? returnPath);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckoutRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckoutRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckoutRequest call({
    String plan,
    PaymentMethodEnum method,
    String? phone,
    String? returnPath,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCheckoutRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCheckoutRequest.copyWith.fieldName(...)`
class _$CheckoutRequestCWProxyImpl implements _$CheckoutRequestCWProxy {
  const _$CheckoutRequestCWProxyImpl(this._value);

  final CheckoutRequest _value;

  @override
  CheckoutRequest plan(String plan) => this(plan: plan);

  @override
  CheckoutRequest method(PaymentMethodEnum method) => this(method: method);

  @override
  CheckoutRequest phone(String? phone) => this(phone: phone);

  @override
  CheckoutRequest returnPath(String? returnPath) =>
      this(returnPath: returnPath);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckoutRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckoutRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckoutRequest call({
    Object? plan = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? phone = const $CopyWithPlaceholder(),
    Object? returnPath = const $CopyWithPlaceholder(),
  }) {
    return CheckoutRequest(
      plan: plan == const $CopyWithPlaceholder()
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as String,
      method: method == const $CopyWithPlaceholder()
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as PaymentMethodEnum,
      phone: phone == const $CopyWithPlaceholder()
          ? _value.phone
          // ignore: cast_nullable_to_non_nullable
          : phone as String?,
      returnPath: returnPath == const $CopyWithPlaceholder()
          ? _value.returnPath
          // ignore: cast_nullable_to_non_nullable
          : returnPath as String?,
    );
  }
}

extension $CheckoutRequestCopyWith on CheckoutRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCheckoutRequest.copyWith(...)` or like so:`instanceOfCheckoutRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckoutRequestCWProxy get copyWith => _$CheckoutRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutRequest _$CheckoutRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CheckoutRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['plan', 'method']);
      final val = CheckoutRequest(
        plan: $checkedConvert('plan', (v) => v as String),
        method: $checkedConvert(
          'method',
          (v) => $enumDecode(_$PaymentMethodEnumEnumMap, v),
        ),
        phone: $checkedConvert('phone', (v) => v as String?),
        returnPath: $checkedConvert('return_path', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'returnPath': 'return_path'});

Map<String, dynamic> _$CheckoutRequestToJson(CheckoutRequest instance) =>
    <String, dynamic>{
      'plan': instance.plan,
      'method': _$PaymentMethodEnumEnumMap[instance.method]!,
      'phone': ?instance.phone,
      'return_path': ?instance.returnPath,
    };

const _$PaymentMethodEnumEnumMap = {
  PaymentMethodEnum.mobile: 'mobile',
  PaymentMethodEnum.card: 'card',
};
