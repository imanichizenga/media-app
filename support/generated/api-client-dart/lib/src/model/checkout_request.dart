//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/payment_method_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkout_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckoutRequest {
  /// Returns a new [CheckoutRequest] instance.
  CheckoutRequest({
    required this.plan,

    required this.method,

    this.phone,

    this.returnPath,
  });

  @JsonKey(name: r'plan', required: true, includeIfNull: false)
  final String plan;

  @JsonKey(name: r'method', required: true, includeIfNull: false)
  final PaymentMethodEnum method;

  @JsonKey(name: r'phone', required: false, includeIfNull: false)
  final String? phone;

  /// Where a card checkout comes back to, on the site
  @JsonKey(name: r'return_path', required: false, includeIfNull: false)
  final String? returnPath;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutRequest &&
          other.plan == plan &&
          other.method == method &&
          other.phone == phone &&
          other.returnPath == returnPath;

  @override
  int get hashCode =>
      plan.hashCode + method.hashCode + phone.hashCode + returnPath.hashCode;

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckoutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
