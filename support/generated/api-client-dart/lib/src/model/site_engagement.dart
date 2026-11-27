//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_engagement.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteEngagement {
  /// Returns a new [SiteEngagement] instance.
  SiteEngagement({required this.cardCounts});

  @JsonKey(name: r'card_counts', required: true, includeIfNull: false)
  final bool cardCounts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteEngagement && other.cardCounts == cardCounts;

  @override
  int get hashCode => cardCounts.hashCode;

  factory SiteEngagement.fromJson(Map<String, dynamic> json) =>
      _$SiteEngagementFromJson(json);

  Map<String, dynamic> toJson() => _$SiteEngagementToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
