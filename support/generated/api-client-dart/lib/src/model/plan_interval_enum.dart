//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// * `month` - Month * `year` - Year
enum PlanIntervalEnum {
  @JsonValue(r'month')
  month(r'month'),
  @JsonValue(r'year')
  year(r'year');

  const PlanIntervalEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
