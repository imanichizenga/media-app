// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signed_in.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SignedInCWProxy {
  SignedIn access(String access);

  SignedIn refresh(String refresh);

  SignedIn expiresIn(int expiresIn);

  SignedIn created(bool? created);

  SignedIn user(Reader user);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignedIn(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignedIn(...).copyWith(id: 12, name: "My name")
  /// ````
  SignedIn call({
    String access,
    String refresh,
    int expiresIn,
    bool? created,
    Reader user,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSignedIn.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSignedIn.copyWith.fieldName(...)`
class _$SignedInCWProxyImpl implements _$SignedInCWProxy {
  const _$SignedInCWProxyImpl(this._value);

  final SignedIn _value;

  @override
  SignedIn access(String access) => this(access: access);

  @override
  SignedIn refresh(String refresh) => this(refresh: refresh);

  @override
  SignedIn expiresIn(int expiresIn) => this(expiresIn: expiresIn);

  @override
  SignedIn created(bool? created) => this(created: created);

  @override
  SignedIn user(Reader user) => this(user: user);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SignedIn(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SignedIn(...).copyWith(id: 12, name: "My name")
  /// ````
  SignedIn call({
    Object? access = const $CopyWithPlaceholder(),
    Object? refresh = const $CopyWithPlaceholder(),
    Object? expiresIn = const $CopyWithPlaceholder(),
    Object? created = const $CopyWithPlaceholder(),
    Object? user = const $CopyWithPlaceholder(),
  }) {
    return SignedIn(
      access: access == const $CopyWithPlaceholder()
          ? _value.access
          // ignore: cast_nullable_to_non_nullable
          : access as String,
      refresh: refresh == const $CopyWithPlaceholder()
          ? _value.refresh
          // ignore: cast_nullable_to_non_nullable
          : refresh as String,
      expiresIn: expiresIn == const $CopyWithPlaceholder()
          ? _value.expiresIn
          // ignore: cast_nullable_to_non_nullable
          : expiresIn as int,
      created: created == const $CopyWithPlaceholder()
          ? _value.created
          // ignore: cast_nullable_to_non_nullable
          : created as bool?,
      user: user == const $CopyWithPlaceholder()
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as Reader,
    );
  }
}

extension $SignedInCopyWith on SignedIn {
  /// Returns a callable class that can be used as follows: `instanceOfSignedIn.copyWith(...)` or like so:`instanceOfSignedIn.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SignedInCWProxy get copyWith => _$SignedInCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignedIn _$SignedInFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SignedIn', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['access', 'refresh', 'expires_in', 'user'],
      );
      final val = SignedIn(
        access: $checkedConvert('access', (v) => v as String),
        refresh: $checkedConvert('refresh', (v) => v as String),
        expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
        created: $checkedConvert('created', (v) => v as bool?),
        user: $checkedConvert(
          'user',
          (v) => Reader.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresIn': 'expires_in'});

Map<String, dynamic> _$SignedInToJson(SignedIn instance) => <String, dynamic>{
  'access': instance.access,
  'refresh': instance.refresh,
  'expires_in': instance.expiresIn,
  'created': ?instance.created,
  'user': instance.user.toJson(),
};
