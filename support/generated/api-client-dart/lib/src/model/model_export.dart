//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:news_api_client/src/model/reader.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'model_export.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ModelExport {
  /// Returns a new [ModelExport] instance.
  ModelExport({
    required this.account,

    required this.identities,

    required this.consents,

    required this.likes,

    required this.bookmarks,

    required this.comments,

    required this.follows,
  });

  @JsonKey(name: r'account', required: true, includeIfNull: false)
  final Reader account;

  @JsonKey(name: r'identities', required: true, includeIfNull: false)
  final List<Map<String, Object?>> identities;

  @JsonKey(name: r'consents', required: true, includeIfNull: false)
  final List<Map<String, Object?>> consents;

  @JsonKey(name: r'likes', required: true, includeIfNull: false)
  final List<Map<String, Object?>> likes;

  @JsonKey(name: r'bookmarks', required: true, includeIfNull: false)
  final List<Map<String, Object?>> bookmarks;

  @JsonKey(name: r'comments', required: true, includeIfNull: false)
  final List<Map<String, Object?>> comments;

  @JsonKey(name: r'follows', required: true, includeIfNull: false)
  final List<Map<String, Object?>> follows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelExport &&
          other.account == account &&
          other.identities == identities &&
          other.consents == consents &&
          other.likes == likes &&
          other.bookmarks == bookmarks &&
          other.comments == comments &&
          other.follows == follows;

  @override
  int get hashCode =>
      account.hashCode +
      identities.hashCode +
      consents.hashCode +
      likes.hashCode +
      bookmarks.hashCode +
      comments.hashCode +
      follows.hashCode;

  factory ModelExport.fromJson(Map<String, dynamic> json) =>
      _$ModelExportFromJson(json);

  Map<String, dynamic> toJson() => _$ModelExportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
