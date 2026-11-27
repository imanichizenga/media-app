//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/methods_enum.dart';
import 'package:news_api_client/src/model/locale_enum.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reader.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Reader {
  /// Returns a new [Reader] instance.
  Reader({
    required this.id,

    required this.displayName,

    required this.username,

    required this.initial,

    required this.phone,

    required this.email,

    required this.locale,

    required this.methods,

    required this.onboarding,

    required this.hideFromReaders,

    required this.joined,
  });

  @JsonKey(name: r'id', required: true, includeIfNull: false)
  final String id;

  @JsonKey(name: r'display_name', required: true, includeIfNull: false)
  final String displayName;

  @JsonKey(name: r'username', required: true, includeIfNull: false)
  final String username;

  @JsonKey(name: r'initial', required: true, includeIfNull: false)
  final String initial;

  @JsonKey(name: r'phone', required: true, includeIfNull: false)
  final String phone;

  @JsonKey(name: r'email', required: true, includeIfNull: false)
  final String email;

  @JsonKey(name: r'locale', required: true, includeIfNull: false)
  final LocaleEnum locale;

  @JsonKey(name: r'methods', required: true, includeIfNull: false)
  final List<MethodsEnum> methods;

  /// A name and the terms are still to come.
  @JsonKey(name: r'onboarding', required: true, includeIfNull: false)
  final bool onboarding;

  @JsonKey(name: r'hide_from_readers', required: true, includeIfNull: false)
  final bool hideFromReaders;

  @JsonKey(name: r'joined', required: true, includeIfNull: false)
  final DateTime joined;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reader &&
          other.id == id &&
          other.displayName == displayName &&
          other.username == username &&
          other.initial == initial &&
          other.phone == phone &&
          other.email == email &&
          other.locale == locale &&
          other.methods == methods &&
          other.onboarding == onboarding &&
          other.hideFromReaders == hideFromReaders &&
          other.joined == joined;

  @override
  int get hashCode =>
      id.hashCode +
      displayName.hashCode +
      username.hashCode +
      initial.hashCode +
      phone.hashCode +
      email.hashCode +
      locale.hashCode +
      methods.hashCode +
      onboarding.hashCode +
      hideFromReaders.hashCode +
      joined.hashCode;

  factory Reader.fromJson(Map<String, dynamic> json) => _$ReaderFromJson(json);

  Map<String, dynamic> toJson() => _$ReaderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
