//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/plan.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'my_subscription.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MySubscription {
  /// Returns a new [MySubscription] instance.
  MySubscription({
    required this.active,

    required this.plan,

    required this.endsAt,
  });

  @JsonKey(name: r'active', required: true, includeIfNull: false)
  final bool active;

  @JsonKey(name: r'plan', required: true, includeIfNull: true)
  final Plan? plan;

  @JsonKey(name: r'ends_at', required: true, includeIfNull: true)
  final DateTime? endsAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MySubscription &&
          other.active == active &&
          other.plan == plan &&
          other.endsAt == endsAt;

  @override
  int get hashCode =>
      active.hashCode +
      (plan == null ? 0 : plan.hashCode) +
      (endsAt == null ? 0 : endsAt.hashCode);

  factory MySubscription.fromJson(Map<String, dynamic> json) =>
      _$MySubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$MySubscriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
