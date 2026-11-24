// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CardCWProxy {
  Card id(String id);

  Card type(PostTypeEnum type);

  Card locale(String locale);

  Card path(String path);

  Card slug(String slug);

  Card headline(String headline);

  Card standfirst(String standfirst);

  Card category(PublicCategory category);

  Card authors(List<CardByline> authors);

  Card image(PublicImage? image);

  Card video(PublicVideo? video);

  Card youtubeId(String youtubeId);

  Card durationMs(int? durationMs);

  Card readingMinutes(int readingMinutes);

  Card publishedAt(DateTime publishedAt);

  Card modifiedAt(DateTime modifiedAt);

  Card isSensitive(bool isSensitive);

  Card breakingUntil(DateTime? breakingUntil);

  Card isLive(bool isLive);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Card(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Card(...).copyWith(id: 12, name: "My name")
  /// ````
  Card call({
    String id,
    PostTypeEnum type,
    String locale,
    String path,
    String slug,
    String headline,
    String standfirst,
    PublicCategory category,
    List<CardByline> authors,
    PublicImage? image,
    PublicVideo? video,
    String youtubeId,
    int? durationMs,
    int readingMinutes,
    DateTime publishedAt,
    DateTime modifiedAt,
    bool isSensitive,
    DateTime? breakingUntil,
    bool isLive,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCard.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCard.copyWith.fieldName(...)`
class _$CardCWProxyImpl implements _$CardCWProxy {
  const _$CardCWProxyImpl(this._value);

  final Card _value;

  @override
  Card id(String id) => this(id: id);

  @override
  Card type(PostTypeEnum type) => this(type: type);

  @override
  Card locale(String locale) => this(locale: locale);

  @override
  Card path(String path) => this(path: path);

  @override
  Card slug(String slug) => this(slug: slug);

  @override
  Card headline(String headline) => this(headline: headline);

  @override
  Card standfirst(String standfirst) => this(standfirst: standfirst);

  @override
  Card category(PublicCategory category) => this(category: category);

  @override
  Card authors(List<CardByline> authors) => this(authors: authors);

  @override
  Card image(PublicImage? image) => this(image: image);

  @override
  Card video(PublicVideo? video) => this(video: video);

  @override
  Card youtubeId(String youtubeId) => this(youtubeId: youtubeId);

  @override
  Card durationMs(int? durationMs) => this(durationMs: durationMs);

  @override
  Card readingMinutes(int readingMinutes) =>
      this(readingMinutes: readingMinutes);

  @override
  Card publishedAt(DateTime publishedAt) => this(publishedAt: publishedAt);

  @override
  Card modifiedAt(DateTime modifiedAt) => this(modifiedAt: modifiedAt);

  @override
  Card isSensitive(bool isSensitive) => this(isSensitive: isSensitive);

  @override
  Card breakingUntil(DateTime? breakingUntil) =>
      this(breakingUntil: breakingUntil);

  @override
  Card isLive(bool isLive) => this(isLive: isLive);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Card(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Card(...).copyWith(id: 12, name: "My name")
  /// ````
  Card call({
    Object? id = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? slug = const $CopyWithPlaceholder(),
    Object? headline = const $CopyWithPlaceholder(),
    Object? standfirst = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? authors = const $CopyWithPlaceholder(),
    Object? image = const $CopyWithPlaceholder(),
    Object? video = const $CopyWithPlaceholder(),
    Object? youtubeId = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? readingMinutes = const $CopyWithPlaceholder(),
    Object? publishedAt = const $CopyWithPlaceholder(),
    Object? modifiedAt = const $CopyWithPlaceholder(),
    Object? isSensitive = const $CopyWithPlaceholder(),
    Object? breakingUntil = const $CopyWithPlaceholder(),
    Object? isLive = const $CopyWithPlaceholder(),
  }) {
    return Card(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as PostTypeEnum,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      slug: slug == const $CopyWithPlaceholder()
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      headline: headline == const $CopyWithPlaceholder()
          ? _value.headline
          // ignore: cast_nullable_to_non_nullable
          : headline as String,
      standfirst: standfirst == const $CopyWithPlaceholder()
          ? _value.standfirst
          // ignore: cast_nullable_to_non_nullable
          : standfirst as String,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as PublicCategory,
      authors: authors == const $CopyWithPlaceholder()
          ? _value.authors
          // ignore: cast_nullable_to_non_nullable
          : authors as List<CardByline>,
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
      readingMinutes: readingMinutes == const $CopyWithPlaceholder()
          ? _value.readingMinutes
          // ignore: cast_nullable_to_non_nullable
          : readingMinutes as int,
      publishedAt: publishedAt == const $CopyWithPlaceholder()
          ? _value.publishedAt
          // ignore: cast_nullable_to_non_nullable
          : publishedAt as DateTime,
      modifiedAt: modifiedAt == const $CopyWithPlaceholder()
          ? _value.modifiedAt
          // ignore: cast_nullable_to_non_nullable
          : modifiedAt as DateTime,
      isSensitive: isSensitive == const $CopyWithPlaceholder()
          ? _value.isSensitive
          // ignore: cast_nullable_to_non_nullable
          : isSensitive as bool,
      breakingUntil: breakingUntil == const $CopyWithPlaceholder()
          ? _value.breakingUntil
          // ignore: cast_nullable_to_non_nullable
          : breakingUntil as DateTime?,
      isLive: isLive == const $CopyWithPlaceholder()
          ? _value.isLive
          // ignore: cast_nullable_to_non_nullable
          : isLive as bool,
    );
  }
}

extension $CardCopyWith on Card {
  /// Returns a callable class that can be used as follows: `instanceOfCard.copyWith(...)` or like so:`instanceOfCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CardCWProxy get copyWith => _$CardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Card _$CardFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Card',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'type',
            'locale',
            'path',
            'slug',
            'headline',
            'standfirst',
            'category',
            'authors',
            'image',
            'video',
            'youtube_id',
            'duration_ms',
            'reading_minutes',
            'published_at',
            'modified_at',
            'is_sensitive',
            'breaking_until',
            'is_live'
          ],
        );
        final val = Card(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert(
              'type', (v) => $enumDecode(_$PostTypeEnumEnumMap, v)),
          locale: $checkedConvert('locale', (v) => v as String),
          path: $checkedConvert('path', (v) => v as String),
          slug: $checkedConvert('slug', (v) => v as String),
          headline: $checkedConvert('headline', (v) => v as String),
          standfirst: $checkedConvert('standfirst', (v) => v as String),
          category: $checkedConvert('category',
              (v) => PublicCategory.fromJson(v as Map<String, dynamic>)),
          authors: $checkedConvert(
              'authors',
              (v) => (v as List<dynamic>)
                  .map((e) => CardByline.fromJson(e as Map<String, dynamic>))
                  .toList()),
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
          readingMinutes:
              $checkedConvert('reading_minutes', (v) => (v as num).toInt()),
          publishedAt: $checkedConvert(
              'published_at', (v) => DateTime.parse(v as String)),
          modifiedAt: $checkedConvert(
              'modified_at', (v) => DateTime.parse(v as String)),
          isSensitive: $checkedConvert('is_sensitive', (v) => v as bool),
          breakingUntil: $checkedConvert('breaking_until',
              (v) => v == null ? null : DateTime.parse(v as String)),
          isLive: $checkedConvert('is_live', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'youtubeId': 'youtube_id',
        'durationMs': 'duration_ms',
        'readingMinutes': 'reading_minutes',
        'publishedAt': 'published_at',
        'modifiedAt': 'modified_at',
        'isSensitive': 'is_sensitive',
        'breakingUntil': 'breaking_until',
        'isLive': 'is_live'
      },
    );

Map<String, dynamic> _$CardToJson(Card instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$PostTypeEnumEnumMap[instance.type]!,
      'locale': instance.locale,
      'path': instance.path,
      'slug': instance.slug,
      'headline': instance.headline,
      'standfirst': instance.standfirst,
      'category': instance.category.toJson(),
      'authors': instance.authors.map((e) => e.toJson()).toList(),
      'image': instance.image?.toJson(),
      'video': instance.video?.toJson(),
      'youtube_id': instance.youtubeId,
      'duration_ms': instance.durationMs,
      'reading_minutes': instance.readingMinutes,
      'published_at': instance.publishedAt.toIso8601String(),
      'modified_at': instance.modifiedAt.toIso8601String(),
      'is_sensitive': instance.isSensitive,
      'breaking_until': instance.breakingUntil?.toIso8601String(),
      'is_live': instance.isLive,
    };

const _$PostTypeEnumEnumMap = {
  PostTypeEnum.article: 'article',
  PostTypeEnum.breaking: 'breaking',
  PostTypeEnum.video: 'video',
  PostTypeEnum.gallery: 'gallery',
  PostTypeEnum.liveBlog: 'live_blog',
  PostTypeEnum.liveStream: 'live_stream',
  PostTypeEnum.opinion: 'opinion',
  PostTypeEnum.short: 'short',
  PostTypeEnum.youtube: 'youtube',
  PostTypeEnum.instagramImport: 'instagram_import',
};
