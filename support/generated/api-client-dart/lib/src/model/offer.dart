//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/payment_method_enum.dart';
import 'package:news_api_client/src/model/plan.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Offer {
  /// Returns a new [Offer] instance.
  Offer({
    required this.enabled,

    required this.previewParagraphs,

    required this.methods,

    required this.plans,
  });

  @JsonKey(name: r'enabled', required: true, includeIfNull: false)
  final bool enabled;

  @JsonKey(name: r'preview_paragraphs', required: true, includeIfNull: false)
  final int previewParagraphs;

  @JsonKey(name: r'methods', required: true, includeIfNull: false)
  final List<PaymentMethodEnum> methods;

  @JsonKey(name: r'plans', required: true, includeIfNull: false)
  final List<Plan> plans;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Offer &&
          other.enabled == enabled &&
          other.previewParagraphs == previewParagraphs &&
          other.methods == methods &&
          other.plans == plans;

  @override
  int get hashCode =>
      enabled.hashCode +
      previewParagraphs.hashCode +
      methods.hashCode +
      plans.hashCode;

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);

  Map<String, dynamic> toJson() => _$OfferToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
