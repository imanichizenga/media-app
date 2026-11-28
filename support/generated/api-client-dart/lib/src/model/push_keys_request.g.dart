// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_keys_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PushKeysRequestCWProxy {
  PushKeysRequest p256dh(String p256dh);

  PushKeysRequest auth(String auth);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PushKeysRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PushKeysRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PushKeysRequest call({String p256dh, String auth});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPushKeysRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPushKeysRequest.copyWith.fieldName(...)`
class _$PushKeysRequestCWProxyImpl implements _$PushKeysRequestCWProxy {
  const _$PushKeysRequestCWProxyImpl(this._value);

  final PushKeysRequest _value;

  @override
  PushKeysRequest p256dh(String p256dh) => this(p256dh: p256dh);

  @override
  PushKeysRequest auth(String auth) => this(auth: auth);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PushKeysRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PushKeysRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  PushKeysRequest call({
    Object? p256dh = const $CopyWithPlaceholder(),
    Object? auth = const $CopyWithPlaceholder(),
  }) {
    return PushKeysRequest(
      p256dh: p256dh == const $CopyWithPlaceholder()
          ? _value.p256dh
          // ignore: cast_nullable_to_non_nullable
          : p256dh as String,
      auth: auth == const $CopyWithPlaceholder()
          ? _value.auth
          // ignore: cast_nullable_to_non_nullable
          : auth as String,
    );
  }
}

extension $PushKeysRequestCopyWith on PushKeysRequest {
  /// Returns a callable class that can be used as follows: `instanceOfPushKeysRequest.copyWith(...)` or like so:`instanceOfPushKeysRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PushKeysRequestCWProxy get copyWith => _$PushKeysRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushKeysRequest _$PushKeysRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PushKeysRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['p256dh', 'auth']);
      final val = PushKeysRequest(
        p256dh: $checkedConvert('p256dh', (v) => v as String),
        auth: $checkedConvert('auth', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PushKeysRequestToJson(PushKeysRequest instance) =>
    <String, dynamic>{'p256dh': instance.p256dh, 'auth': instance.auth};
