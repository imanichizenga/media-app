//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/locale_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patched_profile_request.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PatchedProfileRequest {
  /// Returns a new [PatchedProfileRequest] instance.
  PatchedProfileRequest({
    this.displayName,

    this.username,

    this.locale,

    this.acceptTerms,

    this.hideFromReaders,

    this.bio,

    this.contactEmail,
  });

  @JsonKey(name: r'display_name', required: false, includeIfNull: false)
  final String? displayName;

  @JsonKey(name: r'username', required: false, includeIfNull: false)
  final String? username;

  @JsonKey(name: r'locale', required: false, includeIfNull: false)
  final LocaleEnum? locale;

  @JsonKey(name: r'accept_terms', required: false, includeIfNull: false)
  final bool? acceptTerms;

  @JsonKey(name: r'hide_from_readers', required: false, includeIfNull: false)
  final bool? hideFromReaders;

  @JsonKey(name: r'bio', required: false, includeIfNull: false)
  final String? bio;

  @JsonKey(name: r'contact_email', required: false, includeIfNull: false)
  final String? contactEmail;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchedProfileRequest &&
          other.displayName == displayName &&
          other.username == username &&
          other.locale == locale &&
          other.acceptTerms == acceptTerms &&
          other.hideFromReaders == hideFromReaders &&
          other.bio == bio &&
          other.contactEmail == contactEmail;

  @override
  int get hashCode =>
      displayName.hashCode +
      username.hashCode +
      locale.hashCode +
      acceptTerms.hashCode +
      hideFromReaders.hashCode +
      bio.hashCode +
      contactEmail.hashCode;

  factory PatchedProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$PatchedProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PatchedProfileRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
