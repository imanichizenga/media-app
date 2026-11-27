// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reader_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReaderEntryCWProxy {
  ReaderEntry name(String name);

  ReaderEntry username(String username);

  ReaderEntry initial(String initial);

  ReaderEntry at(DateTime at);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReaderEntry(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReaderEntry(...).copyWith(id: 12, name: "My name")
  /// ````
  ReaderEntry call({String name, String username, String initial, DateTime at});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfReaderEntry.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfReaderEntry.copyWith.fieldName(...)`
class _$ReaderEntryCWProxyImpl implements _$ReaderEntryCWProxy {
  const _$ReaderEntryCWProxyImpl(this._value);

  final ReaderEntry _value;

  @override
  ReaderEntry name(String name) => this(name: name);

  @override
  ReaderEntry username(String username) => this(username: username);

  @override
  ReaderEntry initial(String initial) => this(initial: initial);

  @override
  ReaderEntry at(DateTime at) => this(at: at);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ReaderEntry(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ReaderEntry(...).copyWith(id: 12, name: "My name")
  /// ````
  ReaderEntry call({
    Object? name = const $CopyWithPlaceholder(),
    Object? username = const $CopyWithPlaceholder(),
    Object? initial = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return ReaderEntry(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      username: username == const $CopyWithPlaceholder()
          ? _value.username
          // ignore: cast_nullable_to_non_nullable
          : username as String,
      initial: initial == const $CopyWithPlaceholder()
          ? _value.initial
          // ignore: cast_nullable_to_non_nullable
          : initial as String,
      at: at == const $CopyWithPlaceholder()
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
    );
  }
}

extension $ReaderEntryCopyWith on ReaderEntry {
  /// Returns a callable class that can be used as follows: `instanceOfReaderEntry.copyWith(...)` or like so:`instanceOfReaderEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReaderEntryCWProxy get copyWith => _$ReaderEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReaderEntry _$ReaderEntryFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ReaderEntry',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['name', 'username', 'initial', 'at']);
    final val = ReaderEntry(
      name: $checkedConvert('name', (v) => v as String),
      username: $checkedConvert('username', (v) => v as String),
      initial: $checkedConvert('initial', (v) => v as String),
      at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
    );
    return val;
  },
);

Map<String, dynamic> _$ReaderEntryToJson(ReaderEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'username': instance.username,
      'initial': instance.initial,
      'at': instance.at.toIso8601String(),
    };
