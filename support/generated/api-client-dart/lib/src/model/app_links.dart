//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_links.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppLinks {
  /// Returns a new [AppLinks] instance.
  AppLinks({
    required this.about,
    required this.editorial,
    required this.corrections,
    required this.contact,
    required this.privacy,
    required this.terms,
  });

  @JsonKey(
    name: r'about',
    required: true,
    includeIfNull: false,
  )
  final String about;

  @JsonKey(
    name: r'editorial',
    required: true,
    includeIfNull: false,
  )
  final String editorial;

  @JsonKey(
    name: r'corrections',
    required: true,
    includeIfNull: false,
  )
  final String corrections;

  @JsonKey(
    name: r'contact',
    required: true,
    includeIfNull: false,
  )
  final String contact;

  @JsonKey(
    name: r'privacy',
    required: true,
    includeIfNull: false,
  )
  final String privacy;

  @JsonKey(
    name: r'terms',
    required: true,
    includeIfNull: false,
  )
  final String terms;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLinks &&
          other.about == about &&
          other.editorial == editorial &&
          other.corrections == corrections &&
          other.contact == contact &&
          other.privacy == privacy &&
          other.terms == terms;

  @override
  int get hashCode =>
      about.hashCode +
      editorial.hashCode +
      corrections.hashCode +
      contact.hashCode +
      privacy.hashCode +
      terms.hashCode;

  factory AppLinks.fromJson(Map<String, dynamic> json) =>
      _$AppLinksFromJson(json);

  Map<String, dynamic> toJson() => _$AppLinksToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
