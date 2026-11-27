//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/default_locale_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_localization.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppLocalization {
  /// Returns a new [AppLocalization] instance.
  AppLocalization({required this.defaultLocale, required this.timezone});

  @JsonKey(name: r'default_locale', required: true, includeIfNull: false)
  final DefaultLocaleEnum defaultLocale;

  @JsonKey(name: r'timezone', required: true, includeIfNull: false)
  final String timezone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLocalization &&
          other.defaultLocale == defaultLocale &&
          other.timezone == timezone;

  @override
  int get hashCode => defaultLocale.hashCode + timezone.hashCode;

  factory AppLocalization.fromJson(Map<String, dynamic> json) =>
      _$AppLocalizationFromJson(json);

  Map<String, dynamic> toJson() => _$AppLocalizationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
