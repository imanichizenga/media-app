//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'following.g.dart';

@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Following {
  /// Returns a new [Following] instance.
  Following({required this.following});

  @JsonKey(name: r'following', required: true, includeIfNull: false)
  final bool following;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Following && other.following == following;

  @override
  int get hashCode => following.hashCode;

  factory Following.fromJson(Map<String, dynamic> json) =>
      _$FollowingFromJson(json);

  Map<String, dynamic> toJson() => _$FollowingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
