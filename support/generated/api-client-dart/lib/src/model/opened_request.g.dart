// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opened_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OpenedRequestCWProxy {
  OpenedRequest device(String? device);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OpenedRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OpenedRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  OpenedRequest call({String? device});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOpenedRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOpenedRequest.copyWith.fieldName(...)`
class _$OpenedRequestCWProxyImpl implements _$OpenedRequestCWProxy {
  const _$OpenedRequestCWProxyImpl(this._value);

  final OpenedRequest _value;

  @override
  OpenedRequest device(String? device) => this(device: device);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OpenedRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OpenedRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  OpenedRequest call({Object? device = const $CopyWithPlaceholder()}) {
    return OpenedRequest(
      device: device == const $CopyWithPlaceholder()
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as String?,
    );
  }
}

extension $OpenedRequestCopyWith on OpenedRequest {
  /// Returns a callable class that can be used as follows: `instanceOfOpenedRequest.copyWith(...)` or like so:`instanceOfOpenedRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OpenedRequestCWProxy get copyWith => _$OpenedRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenedRequest _$OpenedRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OpenedRequest', json, ($checkedConvert) {
      final val = OpenedRequest(
        device: $checkedConvert('device', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$OpenedRequestToJson(OpenedRequest instance) =>
    <String, dynamic>{'device': ?instance.device};
