// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ArticleCWProxy {
  Article id(String id);

  Article type(PostTypeEnum type);

  Article locale(String locale);

  Article path(String path);

  Article slug(String slug);

  Article headline(String headline);

  Article standfirst(String standfirst);

  Article category(PublicCategory category);

  Article authors(List<PublicByline> authors);

  Article image(PublicImage? image);

  Article video(PublicVideo? video);

  Article youtubeId(String youtubeId);

  Article readingMinutes(int readingMinutes);

  Article publishedAt(DateTime publishedAt);

  Article modifiedAt(DateTime modifiedAt);

  Article isSensitive(bool isSensitive);

  Article breakingUntil(DateTime? breakingUntil);

  Article isLive(bool isLive);

  Article body(Map<String, Object?> body);

  Article assets(Map<String, Map<String, Object?>> assets);

  Article links(Map<String, RelatedTarget> links);

  Article breadcrumbs(List<PublicCategory> breadcrumbs);

  Article tags(List<PublicLabel> tags);

  Article regions(List<PublicRegion> regions);

  Article story(PublicStoryRef? story);

  Article engagement(PublicPolicy engagement);

  Article contentWarning(String contentWarning);

  Article sourceUrl(String sourceUrl);

  Article updateNote(String updateNote);

  Article correctionNote(String correctionNote);

  Article seo(PublicSeo seo);

  Article firstPublishedAt(DateTime? firstPublishedAt);

  Article liveEndedAt(DateTime? liveEndedAt);

  Article translations(List<Translation> translations);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Article(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Article(...).copyWith(id: 12, name: "My name")
  /// ````
  Article call({
    String id,
    PostTypeEnum type,
    String locale,
    String path,
    String slug,
    String headline,
    String standfirst,
    PublicCategory category,
    List<PublicByline> authors,
    PublicImage? image,
    PublicVideo? video,
    String youtubeId,
    int readingMinutes,
    DateTime publishedAt,
    DateTime modifiedAt,
    bool isSensitive,
    DateTime? breakingUntil,
    bool isLive,
    Map<String, Object?> body,
    Map<String, Map<String, Object?>> assets,
    Map<String, RelatedTarget> links,
    List<PublicCategory> breadcrumbs,
    List<PublicLabel> tags,
    List<PublicRegion> regions,
    PublicStoryRef? story,
    PublicPolicy engagement,
    String contentWarning,
    String sourceUrl,
    String updateNote,
    String correctionNote,
    PublicSeo seo,
    DateTime? firstPublishedAt,
    DateTime? liveEndedAt,
    List<Translation> translations,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfArticle.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfArticle.copyWith.fieldName(...)`
class _$ArticleCWProxyImpl implements _$ArticleCWProxy {
  const _$ArticleCWProxyImpl(this._value);

  final Article _value;

  @override
  Article id(String id) => this(id: id);

  @override
  Article type(PostTypeEnum type) => this(type: type);

  @override
  Article locale(String locale) => this(locale: locale);

  @override
  Article path(String path) => this(path: path);

  @override
  Article slug(String slug) => this(slug: slug);

  @override
  Article headline(String headline) => this(headline: headline);

  @override
  Article standfirst(String standfirst) => this(standfirst: standfirst);

  @override
  Article category(PublicCategory category) => this(category: category);

  @override
  Article authors(List<PublicByline> authors) => this(authors: authors);

  @override
  Article image(PublicImage? image) => this(image: image);

  @override
  Article video(PublicVideo? video) => this(video: video);

  @override
  Article youtubeId(String youtubeId) => this(youtubeId: youtubeId);

  @override
  Article readingMinutes(int readingMinutes) =>
      this(readingMinutes: readingMinutes);

  @override
  Article publishedAt(DateTime publishedAt) => this(publishedAt: publishedAt);

  @override
  Article modifiedAt(DateTime modifiedAt) => this(modifiedAt: modifiedAt);

  @override
  Article isSensitive(bool isSensitive) => this(isSensitive: isSensitive);

  @override
  Article breakingUntil(DateTime? breakingUntil) =>
      this(breakingUntil: breakingUntil);

  @override
  Article isLive(bool isLive) => this(isLive: isLive);

  @override
  Article body(Map<String, Object?> body) => this(body: body);

  @override
  Article assets(Map<String, Map<String, Object?>> assets) =>
      this(assets: assets);

  @override
  Article links(Map<String, RelatedTarget> links) => this(links: links);

  @override
  Article breadcrumbs(List<PublicCategory> breadcrumbs) =>
      this(breadcrumbs: breadcrumbs);

  @override
  Article tags(List<PublicLabel> tags) => this(tags: tags);

  @override
  Article regions(List<PublicRegion> regions) => this(regions: regions);

  @override
  Article story(PublicStoryRef? story) => this(story: story);

  @override
  Article engagement(PublicPolicy engagement) => this(engagement: engagement);

  @override
  Article contentWarning(String contentWarning) =>
      this(contentWarning: contentWarning);

  @override
  Article sourceUrl(String sourceUrl) => this(sourceUrl: sourceUrl);

  @override
  Article updateNote(String updateNote) => this(updateNote: updateNote);

  @override
  Article correctionNote(String correctionNote) =>
      this(correctionNote: correctionNote);

  @override
  Article seo(PublicSeo seo) => this(seo: seo);

  @override
  Article firstPublishedAt(DateTime? firstPublishedAt) =>
      this(firstPublishedAt: firstPublishedAt);

  @override
  Article liveEndedAt(DateTime? liveEndedAt) => this(liveEndedAt: liveEndedAt);

  @override
  Article translations(List<Translation> translations) =>
      this(translations: translations);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Article(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Article(...).copyWith(id: 12, name: "My name")
  /// ````
  Article call({
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
    Object? readingMinutes = const $CopyWithPlaceholder(),
    Object? publishedAt = const $CopyWithPlaceholder(),
    Object? modifiedAt = const $CopyWithPlaceholder(),
    Object? isSensitive = const $CopyWithPlaceholder(),
    Object? breakingUntil = const $CopyWithPlaceholder(),
    Object? isLive = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? assets = const $CopyWithPlaceholder(),
    Object? links = const $CopyWithPlaceholder(),
    Object? breadcrumbs = const $CopyWithPlaceholder(),
    Object? tags = const $CopyWithPlaceholder(),
    Object? regions = const $CopyWithPlaceholder(),
    Object? story = const $CopyWithPlaceholder(),
    Object? engagement = const $CopyWithPlaceholder(),
    Object? contentWarning = const $CopyWithPlaceholder(),
    Object? sourceUrl = const $CopyWithPlaceholder(),
    Object? updateNote = const $CopyWithPlaceholder(),
    Object? correctionNote = const $CopyWithPlaceholder(),
    Object? seo = const $CopyWithPlaceholder(),
    Object? firstPublishedAt = const $CopyWithPlaceholder(),
    Object? liveEndedAt = const $CopyWithPlaceholder(),
    Object? translations = const $CopyWithPlaceholder(),
  }) {
    return Article(
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
          : authors as List<PublicByline>,
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
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as Map<String, Object?>,
      assets: assets == const $CopyWithPlaceholder()
          ? _value.assets
          // ignore: cast_nullable_to_non_nullable
          : assets as Map<String, Map<String, Object?>>,
      links: links == const $CopyWithPlaceholder()
          ? _value.links
          // ignore: cast_nullable_to_non_nullable
          : links as Map<String, RelatedTarget>,
      breadcrumbs: breadcrumbs == const $CopyWithPlaceholder()
          ? _value.breadcrumbs
          // ignore: cast_nullable_to_non_nullable
          : breadcrumbs as List<PublicCategory>,
      tags: tags == const $CopyWithPlaceholder()
          ? _value.tags
          // ignore: cast_nullable_to_non_nullable
          : tags as List<PublicLabel>,
      regions: regions == const $CopyWithPlaceholder()
          ? _value.regions
          // ignore: cast_nullable_to_non_nullable
          : regions as List<PublicRegion>,
      story: story == const $CopyWithPlaceholder()
          ? _value.story
          // ignore: cast_nullable_to_non_nullable
          : story as PublicStoryRef?,
      engagement: engagement == const $CopyWithPlaceholder()
          ? _value.engagement
          // ignore: cast_nullable_to_non_nullable
          : engagement as PublicPolicy,
      contentWarning: contentWarning == const $CopyWithPlaceholder()
          ? _value.contentWarning
          // ignore: cast_nullable_to_non_nullable
          : contentWarning as String,
      sourceUrl: sourceUrl == const $CopyWithPlaceholder()
          ? _value.sourceUrl
          // ignore: cast_nullable_to_non_nullable
          : sourceUrl as String,
      updateNote: updateNote == const $CopyWithPlaceholder()
          ? _value.updateNote
          // ignore: cast_nullable_to_non_nullable
          : updateNote as String,
      correctionNote: correctionNote == const $CopyWithPlaceholder()
          ? _value.correctionNote
          // ignore: cast_nullable_to_non_nullable
          : correctionNote as String,
      seo: seo == const $CopyWithPlaceholder()
          ? _value.seo
          // ignore: cast_nullable_to_non_nullable
          : seo as PublicSeo,
      firstPublishedAt: firstPublishedAt == const $CopyWithPlaceholder()
          ? _value.firstPublishedAt
          // ignore: cast_nullable_to_non_nullable
          : firstPublishedAt as DateTime?,
      liveEndedAt: liveEndedAt == const $CopyWithPlaceholder()
          ? _value.liveEndedAt
          // ignore: cast_nullable_to_non_nullable
          : liveEndedAt as DateTime?,
      translations: translations == const $CopyWithPlaceholder()
          ? _value.translations
          // ignore: cast_nullable_to_non_nullable
          : translations as List<Translation>,
    );
  }
}

extension $ArticleCopyWith on Article {
  /// Returns a callable class that can be used as follows: `instanceOfArticle.copyWith(...)` or like so:`instanceOfArticle.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ArticleCWProxy get copyWith => _$ArticleCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Article _$ArticleFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Article',
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
            'reading_minutes',
            'published_at',
            'modified_at',
            'is_sensitive',
            'breaking_until',
            'is_live',
            'body',
            'assets',
            'links',
            'breadcrumbs',
            'tags',
            'regions',
            'story',
            'engagement',
            'content_warning',
            'source_url',
            'update_note',
            'correction_note',
            'seo',
            'first_published_at',
            'live_ended_at',
            'translations'
          ],
        );
        final val = Article(
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
                  .map((e) => PublicByline.fromJson(e as Map<String, dynamic>))
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
          body: $checkedConvert('body', (v) => v as Map<String, dynamic>),
          assets: $checkedConvert(
              'assets',
              (v) => (v as Map<String, dynamic>).map(
                    (k, e) => MapEntry(k, e as Map<String, dynamic>),
                  )),
          links: $checkedConvert(
              'links',
              (v) => (v as Map<String, dynamic>).map(
                    (k, e) => MapEntry(
                        k, RelatedTarget.fromJson(e as Map<String, dynamic>)),
                  )),
          breadcrumbs: $checkedConvert(
              'breadcrumbs',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => PublicCategory.fromJson(e as Map<String, dynamic>))
                  .toList()),
          tags: $checkedConvert(
              'tags',
              (v) => (v as List<dynamic>)
                  .map((e) => PublicLabel.fromJson(e as Map<String, dynamic>))
                  .toList()),
          regions: $checkedConvert(
              'regions',
              (v) => (v as List<dynamic>)
                  .map((e) => PublicRegion.fromJson(e as Map<String, dynamic>))
                  .toList()),
          story: $checkedConvert(
              'story',
              (v) => v == null
                  ? null
                  : PublicStoryRef.fromJson(v as Map<String, dynamic>)),
          engagement: $checkedConvert('engagement',
              (v) => PublicPolicy.fromJson(v as Map<String, dynamic>)),
          contentWarning:
              $checkedConvert('content_warning', (v) => v as String),
          sourceUrl: $checkedConvert('source_url', (v) => v as String),
          updateNote: $checkedConvert('update_note', (v) => v as String),
          correctionNote:
              $checkedConvert('correction_note', (v) => v as String),
          seo: $checkedConvert(
              'seo', (v) => PublicSeo.fromJson(v as Map<String, dynamic>)),
          firstPublishedAt: $checkedConvert('first_published_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          liveEndedAt: $checkedConvert('live_ended_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          translations: $checkedConvert(
              'translations',
              (v) => (v as List<dynamic>)
                  .map((e) => Translation.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'youtubeId': 'youtube_id',
        'readingMinutes': 'reading_minutes',
        'publishedAt': 'published_at',
        'modifiedAt': 'modified_at',
        'isSensitive': 'is_sensitive',
        'breakingUntil': 'breaking_until',
        'isLive': 'is_live',
        'contentWarning': 'content_warning',
        'sourceUrl': 'source_url',
        'updateNote': 'update_note',
        'correctionNote': 'correction_note',
        'firstPublishedAt': 'first_published_at',
        'liveEndedAt': 'live_ended_at'
      },
    );

Map<String, dynamic> _$ArticleToJson(Article instance) => <String, dynamic>{
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
      'reading_minutes': instance.readingMinutes,
      'published_at': instance.publishedAt.toIso8601String(),
      'modified_at': instance.modifiedAt.toIso8601String(),
      'is_sensitive': instance.isSensitive,
      'breaking_until': instance.breakingUntil?.toIso8601String(),
      'is_live': instance.isLive,
      'body': instance.body,
      'assets': instance.assets,
      'links': instance.links.map((k, e) => MapEntry(k, e.toJson())),
      'breadcrumbs': instance.breadcrumbs.map((e) => e.toJson()).toList(),
      'tags': instance.tags.map((e) => e.toJson()).toList(),
      'regions': instance.regions.map((e) => e.toJson()).toList(),
      'story': instance.story?.toJson(),
      'engagement': instance.engagement.toJson(),
      'content_warning': instance.contentWarning,
      'source_url': instance.sourceUrl,
      'update_note': instance.updateNote,
      'correction_note': instance.correctionNote,
      'seo': instance.seo.toJson(),
      'first_published_at': instance.firstPublishedAt?.toIso8601String(),
      'live_ended_at': instance.liveEndedAt?.toIso8601String(),
      'translations': instance.translations.map((e) => e.toJson()).toList(),
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
