// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sitemap_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SitemapEntryCWProxy {
  SitemapEntry path(String path);

  SitemapEntry locale(String locale);

  SitemapEntry type(String type);

  SitemapEntry headline(String headline);

  SitemapEntry standfirst(String standfirst);

  SitemapEntry publishedAt(DateTime publishedAt);

  SitemapEntry modifiedAt(DateTime modifiedAt);

  SitemapEntry image(PublicImage? image);

  SitemapEntry video(PublicVideo? video);

  SitemapEntry youtubeId(String youtubeId);

  SitemapEntry durationMs(int? durationMs);

  SitemapEntry isSensitive(bool isSensitive);

  SitemapEntry translations(List<SitemapTranslation> translations);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapEntry(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapEntry(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapEntry call({
    String path,
    String locale,
    String type,
    String headline,
    String standfirst,
    DateTime publishedAt,
    DateTime modifiedAt,
    PublicImage? image,
    PublicVideo? video,
    String youtubeId,
    int? durationMs,
    bool isSensitive,
    List<SitemapTranslation> translations,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSitemapEntry.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSitemapEntry.copyWith.fieldName(...)`
class _$SitemapEntryCWProxyImpl implements _$SitemapEntryCWProxy {
  const _$SitemapEntryCWProxyImpl(this._value);

  final SitemapEntry _value;

  @override
  SitemapEntry path(String path) => this(path: path);

  @override
  SitemapEntry locale(String locale) => this(locale: locale);

  @override
  SitemapEntry type(String type) => this(type: type);

  @override
  SitemapEntry headline(String headline) => this(headline: headline);

  @override
  SitemapEntry standfirst(String standfirst) => this(standfirst: standfirst);

  @override
  SitemapEntry publishedAt(DateTime publishedAt) =>
      this(publishedAt: publishedAt);

  @override
  SitemapEntry modifiedAt(DateTime modifiedAt) => this(modifiedAt: modifiedAt);

  @override
  SitemapEntry image(PublicImage? image) => this(image: image);

  @override
  SitemapEntry video(PublicVideo? video) => this(video: video);

  @override
  SitemapEntry youtubeId(String youtubeId) => this(youtubeId: youtubeId);

  @override
  SitemapEntry durationMs(int? durationMs) => this(durationMs: durationMs);

  @override
  SitemapEntry isSensitive(bool isSensitive) => this(isSensitive: isSensitive);

  @override
  SitemapEntry translations(List<SitemapTranslation> translations) =>
      this(translations: translations);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SitemapEntry(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SitemapEntry(...).copyWith(id: 12, name: "My name")
  /// ````
  SitemapEntry call({
    Object? path = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? headline = const $CopyWithPlaceholder(),
    Object? standfirst = const $CopyWithPlaceholder(),
    Object? publishedAt = const $CopyWithPlaceholder(),
    Object? modifiedAt = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? video = const $CopyWithPlaceholder(),
    Object? youtubeId = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? isSensitive = const $CopyWithPlaceholder(),
    Object? translations = const $CopyWithPlaceholder(),
  }) {
    return SitemapEntry(
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      headline: headline == const $CopyWithPlaceholder()
          ? _value.headline
          // ignore: cast_nullable_to_non_nullable
          : headline as String,
      standfirst: standfirst == const $CopyWithPlaceholder()
          ? _value.standfirst
          // ignore: cast_nullable_to_non_nullable
          : standfirst as String,
      publishedAt: publishedAt == const $CopyWithPlaceholder()
          ? _value.publishedAt
          // ignore: cast_nullable_to_non_nullable
          : publishedAt as DateTime,
      modifiedAt: modifiedAt == const $CopyWithPlaceholder()
          ? _value.modifiedAt
          // ignore: cast_nullable_to_non_nullable
          : modifiedAt as DateTime,
      image: image == const $CopyWithPlaceholder()
          ? _value.image
          // ignore: cast_nullable_to_non_nullable
          : image as PublicImage?,
      video: video == const $CopyWithPlaceholder()
          ? _value.video
          // ignore: cast_nullable_to_non_nullable
          : video as PublicVideo?,
      youtubeId: youtubeId == const $CopyWithPlaceholder()
          ? _value.youtubeId
          // ignore: cast_nullable_to_non_nullable
          : youtubeId as String,
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int?,
      isSensitive: isSensitive == const $CopyWithPlaceholder()
          ? _value.isSensitive
          // ignore: cast_nullable_to_non_nullable
          : isSensitive as bool,
      translations: translations == const $CopyWithPlaceholder()
          ? _value.translations
          // ignore: cast_nullable_to_non_nullable
          : translations as List<SitemapTranslation>,
    );
  }
}

extension $SitemapEntryCopyWith on SitemapEntry {
  /// Returns a callable class that can be used as follows: `instanceOfSitemapEntry.copyWith(...)` or like so:`instanceOfSitemapEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SitemapEntryCWProxy get copyWith => _$SitemapEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SitemapEntry _$SitemapEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SitemapEntry',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'path',
            'locale',
            'type',
            'headline',
            'standfirst',
            'published_at',
            'modified_at',
            'image',
            'video',
            'youtube_id',
            'duration_ms',
            'is_sensitive',
            'translations'
          ],
        );
        final val = SitemapEntry(
          path: $checkedConvert('path', (v) => v as String),
          locale: $checkedConvert('locale', (v) => v as String),
          type: $checkedConvert('type', (v) => v as String),
          headline: $checkedConvert('headline', (v) => v as String),
          standfirst: $checkedConvert('standfirst', (v) => v as String),
          publishedAt: $checkedConvert(
              'published_at', (v) => DateTime.parse(v as String)),
          modifiedAt: $checkedConvert(
              'modified_at', (v) => DateTime.parse(v as String)),
          image: $checkedConvert(
              'image',
              (v) => v == null
                  ? null
                  : PublicImage.fromJson(v as Map<String, dynamic>)),
          video: $checkedConvert(
              'video',
              (v) => v == null
                  ? null
                  : PublicVideo.fromJson(v as Map<String, dynamic>)),
          youtubeId: $checkedConvert('youtube_id', (v) => v as String),
          durationMs:
              $checkedConvert('duration_ms', (v) => (v as num?)?.toInt()),
          isSensitive: $checkedConvert('is_sensitive', (v) => v as bool),
          translations: $checkedConvert(
              'translations',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      SitemapTranslation.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'publishedAt': 'published_at',
        'modifiedAt': 'modified_at',
        'youtubeId': 'youtube_id',
        'durationMs': 'duration_ms',
        'isSensitive': 'is_sensitive'
      },
    );

Map<String, dynamic> _$SitemapEntryToJson(SitemapEntry instance) =>
    <String, dynamic>{
      'path': instance.path,
      'locale': instance.locale,
      'type': instance.type,
      'headline': instance.headline,
      'standfirst': instance.standfirst,
      'published_at': instance.publishedAt.toIso8601String(),
      'modified_at': instance.modifiedAt.toIso8601String(),
      'image': instance.image?.toJson(),
      'video': instance.video?.toJson(),
      'youtube_id': instance.youtubeId,
      'duration_ms': instance.durationMs,
      'is_sensitive': instance.isSensitive,
      'translations': instance.translations.map((e) => e.toJson()).toList(),
    };
