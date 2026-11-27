// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'related_target.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RelatedTargetCWProxy {
  RelatedTarget path(String path);

  RelatedTarget headline(String headline);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelatedTarget(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelatedTarget(...).copyWith(id: 12, name: "My name")
  /// ````
  RelatedTarget call({String path, String headline});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRelatedTarget.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRelatedTarget.copyWith.fieldName(...)`
class _$RelatedTargetCWProxyImpl implements _$RelatedTargetCWProxy {
  const _$RelatedTargetCWProxyImpl(this._value);

  final RelatedTarget _value;

  @override
  RelatedTarget path(String path) => this(path: path);

  @override
  RelatedTarget headline(String headline) => this(headline: headline);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RelatedTarget(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RelatedTarget(...).copyWith(id: 12, name: "My name")
  /// ````
  RelatedTarget call({
    Object? path = const $CopyWithPlaceholder(),
    Object? headline = const $CopyWithPlaceholder(),
  }) {
    return RelatedTarget(
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      headline: headline == const $CopyWithPlaceholder()
          ? _value.headline
          // ignore: cast_nullable_to_non_nullable
          : headline as String,
    );
  }
}

extension $RelatedTargetCopyWith on RelatedTarget {
  /// Returns a callable class that can be used as follows: `instanceOfRelatedTarget.copyWith(...)` or like so:`instanceOfRelatedTarget.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RelatedTargetCWProxy get copyWith => _$RelatedTargetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelatedTarget _$RelatedTargetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RelatedTarget', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['path', 'headline']);
      final val = RelatedTarget(
        path: $checkedConvert('path', (v) => v as String),
        headline: $checkedConvert('headline', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$RelatedTargetToJson(RelatedTarget instance) =>
    <String, dynamic>{'path': instance.path, 'headline': instance.headline};
