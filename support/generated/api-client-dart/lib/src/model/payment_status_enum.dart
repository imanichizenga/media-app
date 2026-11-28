//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// * `pending` - Pending * `completed` - Completed * `failed` - Failed * `expired` - Expired * `voided` - Voided
enum PaymentStatusEnum {
  @JsonValue(r'pending')
  pending(r'pending'),
  @JsonValue(r'completed')
  completed(r'completed'),
  @JsonValue(r'failed')
  failed(r'failed'),
  @JsonValue(r'expired')
  expired(r'expired'),
  @JsonValue(r'voided')
  voided(r'voided');

  const PaymentStatusEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
