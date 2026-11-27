//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/reader.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'signed_in.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignedIn {
  /// Returns a new [SignedIn] instance.
  SignedIn({
    required this.access,

    required this.refresh,

    required this.expiresIn,

    this.created,

    required this.user,
  });

  @JsonKey(name: r'access', required: true, includeIfNull: false)
  final String access;

  @JsonKey(name: r'refresh', required: true, includeIfNull: false)
  final String refresh;

  @JsonKey(name: r'expires_in', required: true, includeIfNull: false)
  final int expiresIn;

  @JsonKey(name: r'created', required: false, includeIfNull: false)
  final bool? created;

  @JsonKey(name: r'user', required: true, includeIfNull: false)
  final Reader user;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignedIn &&
          other.access == access &&
          other.refresh == refresh &&
          other.expiresIn == expiresIn &&
          other.created == created &&
          other.user == user;

  @override
  int get hashCode =>
      access.hashCode +
      refresh.hashCode +
      expiresIn.hashCode +
      created.hashCode +
      user.hashCode;

  factory SignedIn.fromJson(Map<String, dynamic> json) =>
      _$SignedInFromJson(json);

  Map<String, dynamic> toJson() => _$SignedInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
