// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PushKeyCWProxy {
  PushKey enabled(bool enabled);

  PushKey publicKey(String publicKey);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PushKey(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PushKey(...).copyWith(id: 12, name: "My name")
  /// ````
  PushKey call({bool enabled, String publicKey});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPushKey.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPushKey.copyWith.fieldName(...)`
class _$PushKeyCWProxyImpl implements _$PushKeyCWProxy {
  const _$PushKeyCWProxyImpl(this._value);

  final PushKey _value;

  @override
  PushKey enabled(bool enabled) => this(enabled: enabled);

  @override
  PushKey publicKey(String publicKey) => this(publicKey: publicKey);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PushKey(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PushKey(...).copyWith(id: 12, name: "My name")
  /// ````
  PushKey call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? publicKey = const $CopyWithPlaceholder(),
  }) {
    return PushKey(
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      publicKey: publicKey == const $CopyWithPlaceholder()
          ? _value.publicKey
          // ignore: cast_nullable_to_non_nullable
          : publicKey as String,
    );
  }
}

extension $PushKeyCopyWith on PushKey {
  /// Returns a callable class that can be used as follows: `instanceOfPushKey.copyWith(...)` or like so:`instanceOfPushKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PushKeyCWProxy get copyWith => _$PushKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushKey _$PushKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PushKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['enabled', 'public_key']);
      final val = PushKey(
        enabled: $checkedConvert('enabled', (v) => v as bool),
        publicKey: $checkedConvert('public_key', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'publicKey': 'public_key'});

Map<String, dynamic> _$PushKeyToJson(PushKey instance) => <String, dynamic>{
  'enabled': instance.enabled,
  'public_key': instance.publicKey,
};
