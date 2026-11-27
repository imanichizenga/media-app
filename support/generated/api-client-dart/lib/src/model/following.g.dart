// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'following.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FollowingCWProxy {
  Following following(bool following);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Following(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Following(...).copyWith(id: 12, name: "My name")
  /// ````
  Following call({bool following});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfFollowing.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfFollowing.copyWith.fieldName(...)`
class _$FollowingCWProxyImpl implements _$FollowingCWProxy {
  const _$FollowingCWProxyImpl(this._value);

  final Following _value;

  @override
  Following following(bool following) => this(following: following);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Following(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Following(...).copyWith(id: 12, name: "My name")
  /// ````
  Following call({Object? following = const $CopyWithPlaceholder()}) {
    return Following(
      following: following == const $CopyWithPlaceholder()
          ? _value.following
          // ignore: cast_nullable_to_non_nullable
          : following as bool,
    );
  }
}

extension $FollowingCopyWith on Following {
  /// Returns a callable class that can be used as follows: `instanceOfFollowing.copyWith(...)` or like so:`instanceOfFollowing.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FollowingCWProxy get copyWith => _$FollowingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Following _$FollowingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Following', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['following']);
      final val = Following(
        following: $checkedConvert('following', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$FollowingToJson(Following instance) => <String, dynamic>{
  'following': instance.following,
};
