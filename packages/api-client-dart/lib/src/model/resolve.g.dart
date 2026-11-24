// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolve.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ResolveCWProxy {
  Resolve path(String path);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Resolve(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Resolve(...).copyWith(id: 12, name: "My name")
  /// ````
  Resolve call({
    String path,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfResolve.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfResolve.copyWith.fieldName(...)`
class _$ResolveCWProxyImpl implements _$ResolveCWProxy {
  const _$ResolveCWProxyImpl(this._value);

  final Resolve _value;

  @override
  Resolve path(String path) => this(path: path);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Resolve(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Resolve(...).copyWith(id: 12, name: "My name")
  /// ````
  Resolve call({
    Object? path = const $CopyWithPlaceholder(),
  }) {
    return Resolve(
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
    );
  }
}

extension $ResolveCopyWith on Resolve {
  /// Returns a callable class that can be used as follows: `instanceOfResolve.copyWith(...)` or like so:`instanceOfResolve.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ResolveCWProxy get copyWith => _$ResolveCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Resolve _$ResolveFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Resolve',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['path'],
        );
        final val = Resolve(
          path: $checkedConvert('path', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$ResolveToJson(Resolve instance) => <String, dynamic>{
      'path': instance.path,
    };
