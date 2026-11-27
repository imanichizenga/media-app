// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_video.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicVideoCWProxy {
  PublicVideo kind(PublicVideoKindEnum kind);

  PublicVideo id(String id);

  PublicVideo alt(String alt);

  PublicVideo credit(String credit);

  PublicVideo width(int? width);

  PublicVideo height(int? height);

  PublicVideo blurhash(String blurhash);

  PublicVideo color(String color);

  PublicVideo durationMs(int? durationMs);

  PublicVideo hls(String hls);

  PublicVideo poster(String poster);

  PublicVideo sprite(String sprite);

  PublicVideo spriteVtt(String spriteVtt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicVideo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicVideo(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicVideo call({
    PublicVideoKindEnum kind,
    String id,
    String alt,
    String credit,
    int? width,
    int? height,
    String blurhash,
    String color,
    int? durationMs,
    String hls,
    String poster,
    String sprite,
    String spriteVtt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicVideo.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicVideo.copyWith.fieldName(...)`
class _$PublicVideoCWProxyImpl implements _$PublicVideoCWProxy {
  const _$PublicVideoCWProxyImpl(this._value);

  final PublicVideo _value;

  @override
  PublicVideo kind(PublicVideoKindEnum kind) => this(kind: kind);

  @override
  PublicVideo id(String id) => this(id: id);

  @override
  PublicVideo alt(String alt) => this(alt: alt);

  @override
  PublicVideo credit(String credit) => this(credit: credit);

  @override
  PublicVideo width(int? width) => this(width: width);

  @override
  PublicVideo height(int? height) => this(height: height);

  @override
  PublicVideo blurhash(String blurhash) => this(blurhash: blurhash);

  @override
  PublicVideo color(String color) => this(color: color);

  @override
  PublicVideo durationMs(int? durationMs) => this(durationMs: durationMs);

  @override
  PublicVideo hls(String hls) => this(hls: hls);

  @override
  PublicVideo poster(String poster) => this(poster: poster);

  @override
  PublicVideo sprite(String sprite) => this(sprite: sprite);

  @override
  PublicVideo spriteVtt(String spriteVtt) => this(spriteVtt: spriteVtt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicVideo(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicVideo(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicVideo call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? alt = const $CopyWithPlaceholder(),
    Object? credit = const $CopyWithPlaceholder(),
    Object? width = const $CopyWithPlaceholder(),
    Object? height = const $CopyWithPlaceholder(),
    Object? blurhash = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? hls = const $CopyWithPlaceholder(),
    Object? poster = const $CopyWithPlaceholder(),
    Object? sprite = const $CopyWithPlaceholder(),
    Object? spriteVtt = const $CopyWithPlaceholder(),
  }) {
    return PublicVideo(
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as PublicVideoKindEnum,
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
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int?,
      hls: hls == const $CopyWithPlaceholder()
          ? _value.hls
          // ignore: cast_nullable_to_non_nullable
          : hls as String,
      poster: poster == const $CopyWithPlaceholder()
          ? _value.poster
          // ignore: cast_nullable_to_non_nullable
          : poster as String,
      sprite: sprite == const $CopyWithPlaceholder()
          ? _value.sprite
          // ignore: cast_nullable_to_non_nullable
          : sprite as String,
      spriteVtt: spriteVtt == const $CopyWithPlaceholder()
          ? _value.spriteVtt
          // ignore: cast_nullable_to_non_nullable
          : spriteVtt as String,
    );
  }
}

extension $PublicVideoCopyWith on PublicVideo {
  /// Returns a callable class that can be used as follows: `instanceOfPublicVideo.copyWith(...)` or like so:`instanceOfPublicVideo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicVideoCWProxy get copyWith => _$PublicVideoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicVideo _$PublicVideoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PublicVideo',
  json,
  ($checkedConvert) {
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
        'duration_ms',
        'hls',
        'poster',
        'sprite',
        'sprite_vtt',
      ],
    );
    final val = PublicVideo(
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$PublicVideoKindEnumEnumMap, v),
      ),
      id: $checkedConvert('id', (v) => v as String),
      alt: $checkedConvert('alt', (v) => v as String),
      credit: $checkedConvert('credit', (v) => v as String),
      width: $checkedConvert('width', (v) => (v as num?)?.toInt()),
      height: $checkedConvert('height', (v) => (v as num?)?.toInt()),
      blurhash: $checkedConvert('blurhash', (v) => v as String),
      color: $checkedConvert('color', (v) => v as String),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num?)?.toInt()),
      hls: $checkedConvert('hls', (v) => v as String),
      poster: $checkedConvert('poster', (v) => v as String),
      sprite: $checkedConvert('sprite', (v) => v as String),
      spriteVtt: $checkedConvert('sprite_vtt', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'durationMs': 'duration_ms', 'spriteVtt': 'sprite_vtt'},
);

Map<String, dynamic> _$PublicVideoToJson(PublicVideo instance) =>
    <String, dynamic>{
      'kind': _$PublicVideoKindEnumEnumMap[instance.kind]!,
      'id': instance.id,
      'alt': instance.alt,
      'credit': instance.credit,
      'width': instance.width,
      'height': instance.height,
      'blurhash': instance.blurhash,
      'color': instance.color,
      'duration_ms': instance.durationMs,
      'hls': instance.hls,
      'poster': instance.poster,
      'sprite': instance.sprite,
      'sprite_vtt': instance.spriteVtt,
    };

const _$PublicVideoKindEnumEnumMap = {PublicVideoKindEnum.video: 'video'};
