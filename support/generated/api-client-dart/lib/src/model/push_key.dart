//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'push_key.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PushKey {
  /// Returns a new [PushKey] instance.
  PushKey({required this.enabled, required this.publicKey});

  /// The newsroom sends notifications of new stories.
  @JsonKey(name: r'enabled', required: true, includeIfNull: false)
  final bool enabled;

  /// VAPID application server key, base64url (applicationServerKey).
  @JsonKey(name: r'public_key', required: true, includeIfNull: false)
  final String publicKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushKey &&
          other.enabled == enabled &&
          other.publicKey == publicKey;

  @override
  int get hashCode => enabled.hashCode + publicKey.hashCode;

  factory PushKey.fromJson(Map<String, dynamic> json) =>
      _$PushKeyFromJson(json);

  Map<String, dynamic> toJson() => _$PushKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
