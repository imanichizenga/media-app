// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SegmentCWProxy {
  Segment text(String text);

  Segment hit(bool hit);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Segment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Segment(...).copyWith(id: 12, name: "My name")
  /// ````
  Segment call({String text, bool hit});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSegment.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSegment.copyWith.fieldName(...)`
class _$SegmentCWProxyImpl implements _$SegmentCWProxy {
  const _$SegmentCWProxyImpl(this._value);

  final Segment _value;

  @override
  Segment text(String text) => this(text: text);

  @override
  Segment hit(bool hit) => this(hit: hit);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Segment(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Segment(...).copyWith(id: 12, name: "My name")
  /// ````
  Segment call({
    Object? text = const $CopyWithPlaceholder(),
    Object? hit = const $CopyWithPlaceholder(),
  }) {
    return Segment(
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
      hit: hit == const $CopyWithPlaceholder()
          ? _value.hit
          // ignore: cast_nullable_to_non_nullable
          : hit as bool,
    );
  }
}

extension $SegmentCopyWith on Segment {
  /// Returns a callable class that can be used as follows: `instanceOfSegment.copyWith(...)` or like so:`instanceOfSegment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SegmentCWProxy get copyWith => _$SegmentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Segment _$SegmentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Segment', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text', 'hit']);
      final val = Segment(
        text: $checkedConvert('text', (v) => v as String),
        hit: $checkedConvert('hit', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$SegmentToJson(Segment instance) => <String, dynamic>{
  'text': instance.text,
  'hit': instance.hit,
};
