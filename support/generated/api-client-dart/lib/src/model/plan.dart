//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/plan_interval_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Plan {
  /// Returns a new [Plan] instance.
  Plan({
    required this.id,

    required this.code,

    required this.interval,

    required this.price,

    required this.currency,

    required this.name,

    required this.tagline,

    required this.features,

    required this.badge,

    required this.tone,

    required this.highlighted,

    required this.monthlyEquivalent,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'code', required: true, includeIfNull: false)
  final String code;

  @JsonKey(name: r'interval', required: true, includeIfNull: false)
  final PlanIntervalEnum interval;

  /// Whole shillings
  @JsonKey(name: r'price', required: true, includeIfNull: false)
  final int price;

  @JsonKey(name: r'currency', required: true, includeIfNull: false)
  final String currency;

  @JsonKey(name: r'name', required: true, includeIfNull: false)
  final String name;

  @JsonKey(name: r'tagline', required: true, includeIfNull: false)
  final String tagline;

  @JsonKey(name: r'features', required: true, includeIfNull: false)
  final List<String> features;

  /// A word on the card's top; empty for none
  @JsonKey(name: r'badge', required: true, includeIfNull: false)
  final String badge;

  /// brand, ember, ocean, forest, violet or night
  @JsonKey(name: r'tone', required: true, includeIfNull: false)
  final String tone;

  @JsonKey(name: r'highlighted', required: true, includeIfNull: false)
  final bool highlighted;

  /// A year's price over twelve; the month's own price otherwise
  @JsonKey(name: r'monthly_equivalent', required: true, includeIfNull: false)
  final int monthlyEquivalent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Plan &&
          other.id == id &&
          other.code == code &&
          other.interval == interval &&
          other.price == price &&
          other.currency == currency &&
          other.name == name &&
          other.tagline == tagline &&
          other.features == features &&
          other.badge == badge &&
          other.tone == tone &&
          other.highlighted == highlighted &&
          other.monthlyEquivalent == monthlyEquivalent;

  @override
  int get hashCode =>
      id.hashCode +
      code.hashCode +
      interval.hashCode +
      price.hashCode +
      currency.hashCode +
      name.hashCode +
      tagline.hashCode +
      features.hashCode +
      badge.hashCode +
      tone.hashCode +
      highlighted.hashCode +
      monthlyEquivalent.hashCode;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
