// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletionCWProxy {
  Deletion graceDays(int graceDays);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Deletion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Deletion(...).copyWith(id: 12, name: "My name")
  /// ````
  Deletion call({int graceDays});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfDeletion.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfDeletion.copyWith.fieldName(...)`
class _$DeletionCWProxyImpl implements _$DeletionCWProxy {
  const _$DeletionCWProxyImpl(this._value);

  final Deletion _value;

  @override
  Deletion graceDays(int graceDays) => this(graceDays: graceDays);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Deletion(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Deletion(...).copyWith(id: 12, name: "My name")
  /// ````
  Deletion call({Object? graceDays = const $CopyWithPlaceholder()}) {
    return Deletion(
      graceDays: graceDays == const $CopyWithPlaceholder()
          ? _value.graceDays
          // ignore: cast_nullable_to_non_nullable
          : graceDays as int,
    );
  }
}

extension $DeletionCopyWith on Deletion {
  /// Returns a callable class that can be used as follows: `instanceOfDeletion.copyWith(...)` or like so:`instanceOfDeletion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletionCWProxy get copyWith => _$DeletionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Deletion _$DeletionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Deletion', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['grace_days']);
      final val = Deletion(
        graceDays: $checkedConvert('grace_days', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'graceDays': 'grace_days'});

Map<String, dynamic> _$DeletionToJson(Deletion instance) => <String, dynamic>{
  'grace_days': instance.graceDays,
};
