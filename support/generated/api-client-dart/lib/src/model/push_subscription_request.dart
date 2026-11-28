//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/locale_enum.dart';
import 'package:news_api_client/src/model/push_keys_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'push_subscription_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PushSubscriptionRequest {
  /// Returns a new [PushSubscriptionRequest] instance.
  PushSubscriptionRequest({
    required this.endpoint,

    required this.keys,

    this.locale,
  });

  @JsonKey(name: r'endpoint', required: true, includeIfNull: false)
  final String endpoint;

  @JsonKey(name: r'keys', required: true, includeIfNull: false)
  final PushKeysRequest keys;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final LocaleEnum? locale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushSubscriptionRequest &&
          other.endpoint == endpoint &&
          other.keys == keys &&
          other.locale == locale;

  @override
  int get hashCode => endpoint.hashCode + keys.hashCode + locale.hashCode;

  factory PushSubscriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$PushSubscriptionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PushSubscriptionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
