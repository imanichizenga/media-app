//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/payment_method_enum.dart';
import 'package:news_api_client/src/model/my_subscription.dart';
import 'package:news_api_client/src/model/payment_status_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Payment {
  /// Returns a new [Payment] instance.
  Payment({
    required this.id,

    required this.status,

    required this.method,

    required this.amount,

    required this.currency,

    required this.plan,

    required this.checkoutUrl,

    required this.completedAt,

    required this.subscription,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'status', required: true, includeIfNull: false)
  final PaymentStatusEnum status;

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final PaymentMethodEnum method;

  @JsonKey(name: r'amount', required: true, includeIfNull: false)
  final int amount;

  @JsonKey(name: r'currency', required: true, includeIfNull: false)
  final String currency;

  @JsonKey(name: r'plan', required: true, includeIfNull: false)
  final String plan;

  /// Cards: send the reader here
  @JsonKey(name: r'checkout_url', required: true, includeIfNull: false)
  final String checkoutUrl;

  @JsonKey(name: r'completed_at', required: true, includeIfNull: true)
  final DateTime? completedAt;

  @JsonKey(name: r'subscription', required: true, includeIfNull: false)
  final MySubscription subscription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          other.id == id &&
          other.status == status &&
          other.method == method &&
          other.amount == amount &&
          other.currency == currency &&
          other.plan == plan &&
          other.checkoutUrl == checkoutUrl &&
          other.completedAt == completedAt &&
          other.subscription == subscription;

  @override
  int get hashCode =>
      id.hashCode +
      status.hashCode +
      method.hashCode +
      amount.hashCode +
      currency.hashCode +
      plan.hashCode +
      checkoutUrl.hashCode +
      (completedAt == null ? 0 : completedAt.hashCode) +
      subscription.hashCode;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
