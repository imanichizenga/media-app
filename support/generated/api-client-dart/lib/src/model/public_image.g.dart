// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_image.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicImageCWProxy {
  PublicImage kind(PublicImageKindEnum kind);

  PublicImage id(String id);

  PublicImage alt(String alt);

  PublicImage credit(String credit);

  PublicImage width(int? width);

  PublicImage height(int? height);

  PublicImage blurhash(String blurhash);

  PublicImage color(String color);

  PublicImage focal(List<int> focal);

  PublicImage base_(String base_);

  PublicImage widths(List<int> widths);

  PublicImage crops(String crops);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicImage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicImage(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicImage call({
    PublicImageKindEnum kind,
    String id,
    String alt,
    String credit,
    int? width,
    int? height,
    String blurhash,
    String color,
    List<int> focal,
    String base_,
    List<int> widths,
    String crops,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicImage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicImage.copyWith.fieldName(...)`
class _$PublicImageCWProxyImpl implements _$PublicImageCWProxy {
  const _$PublicImageCWProxyImpl(this._value);

  final PublicImage _value;

  @override
  PublicImage kind(PublicImageKindEnum kind) => this(kind: kind);

  @override
  PublicImage id(String id) => this(id: id);

  @override
  PublicImage alt(String alt) => this(alt: alt);

  @override
  PublicImage credit(String credit) => this(credit: credit);

  @override
  PublicImage width(int? width) => this(width: width);

  @override
  PublicImage height(int? height) => this(height: height);

  @override
  PublicImage blurhash(String blurhash) => this(blurhash: blurhash);

  @override
  PublicImage color(String color) => this(color: color);

  @override
  PublicImage focal(List<int> focal) => this(focal: focal);

  @override
  PublicImage base_(String base_) => this(base_: base_);

  @override
  PublicImage widths(List<int> widths) => this(widths: widths);

  @override
  PublicImage crops(String crops) => this(crops: crops);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicImage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicImage(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicImage call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? alt = const $CopyWithPlaceholder(),
    Object? credit = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? blurhash = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? focal = const $CopyWithPlaceholder(),
    Object? base_ = const $CopyWithPlaceholder(),
    Object? widths = const $CopyWithPlaceholder(),
    Object? crops = const $CopyWithPlaceholder(),
  }) {
    return PublicImage(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PublicImageKindEnum,
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      alt: alt == const $CopyWithPlaceholder()
          ? _value.alt
          // ignore: cast_nullable_to_non_nullable
          : alt as String,
      credit: credit == const $CopyWithPlaceholder()
          ? _value.credit
          // ignore: cast_nullable_to_non_nullable
          : credit as String,
      width: width == const $CopyWithPlaceholder()
          ? _value.width
          // ignore: cast_nullable_to_non_nullable
          : width as int?,
      height: height == const $CopyWithPlaceholder()
          ? _value.height
          // ignore: cast_nullable_to_non_nullable
          : height as int?,
      blurhash: blurhash == const $CopyWithPlaceholder()
          ? _value.blurhash
          // ignore: cast_nullable_to_non_nullable
          : blurhash as String,
      color: color == const $CopyWithPlaceholder()
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
      focal: focal == const $CopyWithPlaceholder()
          ? _value.focal
          // ignore: cast_nullable_to_non_nullable
          : focal as List<int>,
      base_: base_ == const $CopyWithPlaceholder()
          ? _value.base_
          // ignore: cast_nullable_to_non_nullable
          : base_ as String,
      widths: widths == const $CopyWithPlaceholder()
          ? _value.widths
          // ignore: cast_nullable_to_non_nullable
          : widths as List<int>,
      crops: crops == const $CopyWithPlaceholder()
          ? _value.crops
          // ignore: cast_nullable_to_non_nullable
          : crops as String,
    );
  }
}

extension $PublicImageCopyWith on PublicImage {
  /// Returns a callable class that can be used as follows: `instanceOfPublicImage.copyWith(...)` or like so:`instanceOfPublicImage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicImageCWProxy get copyWith => _$PublicImageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicImage _$PublicImageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicImage', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'kind',
          'id',
          'alt',
          'credit',
          'width',
          'height',
          'blurhash',
          'color',
          'focal',
          'base',
          'widths',
          'crops',
        ],
      );
      final val = PublicImage(
        kind: $checkedConvert(
          'kind',
          (v) => $enumDecode(_$PublicImageKindEnumEnumMap, v),
        ),
        id: $checkedConvert('id', (v) => v as String),
        alt: $checkedConvert('alt', (v) => v as String),
        credit: $checkedConvert('credit', (v) => v as String),
        width: $checkedConvert('width', (v) => (v as num?)?.toInt()),
        height: $checkedConvert('height', (v) => (v as num?)?.toInt()),
        blurhash: $checkedConvert('blurhash', (v) => v as String),
        color: $checkedConvert('color', (v) => v as String),
        focal: $checkedConvert(
          'focal',
          (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
        base_: $checkedConvert('base', (v) => v as String),
        widths: $checkedConvert(
          'widths',
          (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
        ),
        crops: $checkedConvert('crops', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'base_': 'base'});

Map<String, dynamic> _$PublicImageToJson(PublicImage instance) =>
    <String, dynamic>{
      'kind': _$PublicImageKindEnumEnumMap[instance.kind]!,
      'id': instance.id,
      'alt': instance.alt,
      'credit': instance.credit,
      'width': instance.width,
      'height': instance.height,
      'blurhash': instance.blurhash,
      'color': instance.color,
      'focal': instance.focal,
      'base': instance.base_,
      'widths': instance.widths,
      'crops': instance.crops,
    };

const _$PublicImageKindEnumEnumMap = {PublicImageKindEnum.image: 'image'};
