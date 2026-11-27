//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/locale_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'code_request_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CodeRequestRequest {
  /// Returns a new [CodeRequestRequest] instance.
  CodeRequestRequest({required this.phone, this.locale});

  /// As the reader typed it; 0712 345 678 is +255712345678.
  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final LocaleEnum? locale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeRequestRequest &&
          other.phone == phone &&
          other.locale == locale;

  @override
  int get hashCode => phone.hashCode + locale.hashCode;

  factory CodeRequestRequest.fromJson(Map<String, dynamic> json) =>
      _$CodeRequestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CodeRequestRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
