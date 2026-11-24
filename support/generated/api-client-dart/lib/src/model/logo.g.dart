// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logo.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LogoCWProxy {
  Logo id(String id);

  Logo width(int width);

  Logo height(int height);

  Logo derived(bool derived);

  Logo svg(String svg);

  Logo png(Map<String, String> png);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Logo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Logo(...).copyWith(id: 12, name: "My name")
  /// ````
  Logo call({
    String id,
    int width,
    int height,
    bool derived,
    String svg,
    Map<String, String> png,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLogo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLogo.copyWith.fieldName(...)`
class _$LogoCWProxyImpl implements _$LogoCWProxy {
  const _$LogoCWProxyImpl(this._value);

  final Logo _value;

  @override
  Logo id(String id) => this(id: id);

  @override
  Logo width(int width) => this(width: width);

  @override
  Logo height(int height) => this(height: height);

  @override
  Logo derived(bool derived) => this(derived: derived);

  @override
  Logo svg(String svg) => this(svg: svg);

  @override
  Logo png(Map<String, String> png) => this(png: png);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Logo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Logo(...).copyWith(id: 12, name: "My name")
  /// ````
  Logo call({
    Object? id = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? derived = const $CopyWithPlaceholder(),
    Object? svg = const $CopyWithPlaceholder(),
    Object? png = const $CopyWithPlaceholder(),
  }) {
    return Logo(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      width: width == const $CopyWithPlaceholder()
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as int,
      height: height == const $CopyWithPlaceholder()
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as int,
      derived: derived == const $CopyWithPlaceholder()
          ? _value.derived
          // ignore: cast_nullable_to_non_nullable
          : derived as bool,
      svg: svg == const $CopyWithPlaceholder()
          ? _value.svg
          // ignore: cast_nullable_to_non_nullable
          : svg as String,
      png: png == const $CopyWithPlaceholder()
          ? _value.png
          // ignore: cast_nullable_to_non_nullable
          : png as Map<String, String>,
    );
  }
}

extension $LogoCopyWith on Logo {
  /// Returns a callable class that can be used as follows: `instanceOfLogo.copyWith(...)` or like so:`instanceOfLogo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LogoCWProxy get copyWith => _$LogoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Logo _$LogoFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Logo',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'width',
            'height',
            'derived',
            'svg',
            'png'
          ],
        );
        final val = Logo(
          id: $checkedConvert('id', (v) => v as String),
          width: $checkedConvert('width', (v) => (v as num).toInt()),
          height: $checkedConvert('height', (v) => (v as num).toInt()),
          derived: $checkedConvert('derived', (v) => v as bool),
          svg: $checkedConvert('svg', (v) => v as String),
          png:
              $checkedConvert('png', (v) => Map<String, String>.from(v as Map)),
        );
        return val;
      },
    );

Map<String, dynamic> _$LogoToJson(Logo instance) => <String, dynamic>{
      'id': instance.id,
      'width': instance.width,
      'height': instance.height,
      'derived': instance.derived,
      'svg': instance.svg,
      'png': instance.png,
    };
