// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentCWProxy {
  Payment id(String id);

  Payment status(PaymentStatusEnum status);

  Payment method(PaymentMethodEnum method);

  Payment amount(int amount);

  Payment currency(String currency);

  Payment plan(String plan);

  Payment checkoutUrl(String checkoutUrl);

  Payment completedAt(DateTime? completedAt);

  Payment subscription(MySubscription subscription);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Payment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Payment(...).copyWith(id: 12, name: "My name")
  /// ````
  Payment call({
    String id,
    PaymentStatusEnum status,
    PaymentMethodEnum method,
    int amount,
    String currency,
    String plan,
    String checkoutUrl,
    DateTime? completedAt,
    MySubscription subscription,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPayment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPayment.copyWith.fieldName(...)`
class _$PaymentCWProxyImpl implements _$PaymentCWProxy {
  const _$PaymentCWProxyImpl(this._value);

  final Payment _value;

  @override
  Payment id(String id) => this(id: id);

  @override
  Payment status(PaymentStatusEnum status) => this(status: status);

  @override
  Payment method(PaymentMethodEnum method) => this(method: method);

  @override
  Payment amount(int amount) => this(amount: amount);

  @override
  Payment currency(String currency) => this(currency: currency);

  @override
  Payment plan(String plan) => this(plan: plan);

  @override
  Payment checkoutUrl(String checkoutUrl) => this(checkoutUrl: checkoutUrl);

  @override
  Payment completedAt(DateTime? completedAt) => this(completedAt: completedAt);

  @override
  Payment subscription(MySubscription subscription) =>
      this(subscription: subscription);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Payment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Payment(...).copyWith(id: 12, name: "My name")
  /// ````
  Payment call({
    Object? id = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? method = const $CopyWithPlaceholder(),
    Object? amount = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? checkoutUrl = const $CopyWithPlaceholder(),
    Object? completedAt = const $CopyWithPlaceholder(),
    Object? subscription = const $CopyWithPlaceholder(),
  }) {
    return Payment(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PaymentStatusEnum,
      method: method == const $CopyWithPlaceholder()
          ? _value.method
          // ignore: cast_nullable_to_non_nullable
          : method as PaymentMethodEnum,
      amount: amount == const $CopyWithPlaceholder()
          ? _value.amount
          // ignore: cast_nullable_to_non_nullable
          : amount as int,
      currency: currency == const $CopyWithPlaceholder()
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as String,
      plan: plan == const $CopyWithPlaceholder()
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as String,
      checkoutUrl: checkoutUrl == const $CopyWithPlaceholder()
          ? _value.checkoutUrl
          // ignore: cast_nullable_to_non_nullable
          : checkoutUrl as String,
      completedAt: completedAt == const $CopyWithPlaceholder()
          ? _value.completedAt
          // ignore: cast_nullable_to_non_nullable
          : completedAt as DateTime?,
      subscription: subscription == const $CopyWithPlaceholder()
          ? _value.subscription
          // ignore: cast_nullable_to_non_nullable
          : subscription as MySubscription,
    );
  }
}

extension $PaymentCopyWith on Payment {
  /// Returns a callable class that can be used as follows: `instanceOfPayment.copyWith(...)` or like so:`instanceOfPayment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentCWProxy get copyWith => _$PaymentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Payment',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'status',
        'method',
        'amount',
        'currency',
        'plan',
        'checkout_url',
        'completed_at',
        'subscription',
      ],
    );
    final val = Payment(
      id: $checkedConvert('id', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$PaymentStatusEnumEnumMap, v),
      ),
      method: $checkedConvert(
        'method',
        (v) => $enumDecode(_$PaymentMethodEnumEnumMap, v),
      ),
      amount: $checkedConvert('amount', (v) => (v as num).toInt()),
      currency: $checkedConvert('currency', (v) => v as String),
      plan: $checkedConvert('plan', (v) => v as String),
      checkoutUrl: $checkedConvert('checkout_url', (v) => v as String),
      completedAt: $checkedConvert(
        'completed_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      subscription: $checkedConvert(
        'subscription',
        (v) => MySubscription.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'checkoutUrl': 'checkout_url',
    'completedAt': 'completed_at',
  },
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'id': instance.id,
  'status': _$PaymentStatusEnumEnumMap[instance.status]!,
  'method': _$PaymentMethodEnumEnumMap[instance.method]!,
  'amount': instance.amount,
  'currency': instance.currency,
  'plan': instance.plan,
  'checkout_url': instance.checkoutUrl,
  'completed_at': instance.completedAt?.toIso8601String(),
  'subscription': instance.subscription.toJson(),
};

const _$PaymentStatusEnumEnumMap = {
  PaymentStatusEnum.pending: 'pending',
  PaymentStatusEnum.completed: 'completed',
  PaymentStatusEnum.failed: 'failed',
  PaymentStatusEnum.expired: 'expired',
  PaymentStatusEnum.voided: 'voided',
};

const _$PaymentMethodEnumEnumMap = {
  PaymentMethodEnum.mobile: 'mobile',
  PaymentMethodEnum.card: 'card',
};
