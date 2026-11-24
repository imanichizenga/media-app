//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// * `open` - open * `verified` - verified * `premoderated` - premoderated * `closed` - closed
enum CommentsEnum {
  @JsonValue(r'open')
  open(r'open'),
  @JsonValue(r'verified')
  verified(r'verified'),
  @JsonValue(r'premoderated')
  premoderated(r'premoderated'),
  @JsonValue(r'closed')
  closed(r'closed');

  const CommentsEnum(this.value);

  final String value;

  @override
  String toString() => value;
}
