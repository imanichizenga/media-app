// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicPageCWProxy {
  PublicPage key(String key);

  PublicPage locale(String locale);

  PublicPage path(String path);

  PublicPage title(String title);

  PublicPage summary(String summary);

  PublicPage body(Map<String, Object?> body);

  PublicPage assets(Map<String, Map<String, Object?>> assets);

  PublicPage publishedAt(DateTime publishedAt);

  PublicPage modifiedAt(DateTime modifiedAt);

  PublicPage translations(List<PageTranslation> translations);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPage call({
    String key,
    String locale,
    String path,
    String title,
    String summary,
    Map<String, Object?> body,
    Map<String, Map<String, Object?>> assets,
    DateTime publishedAt,
    DateTime modifiedAt,
    List<PageTranslation> translations,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicPage.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicPage.copyWith.fieldName(...)`
class _$PublicPageCWProxyImpl implements _$PublicPageCWProxy {
  const _$PublicPageCWProxyImpl(this._value);

  final PublicPage _value;

  @override
  PublicPage key(String key) => this(key: key);

  @override
  PublicPage locale(String locale) => this(locale: locale);

  @override
  PublicPage path(String path) => this(path: path);

  @override
  PublicPage title(String title) => this(title: title);

  @override
  PublicPage summary(String summary) => this(summary: summary);

  @override
  PublicPage body(Map<String, Object?> body) => this(body: body);

  @override
  PublicPage assets(Map<String, Map<String, Object?>> assets) =>
      this(assets: assets);

  @override
  PublicPage publishedAt(DateTime publishedAt) =>
      this(publishedAt: publishedAt);

  @override
  PublicPage modifiedAt(DateTime modifiedAt) => this(modifiedAt: modifiedAt);

  @override
  PublicPage translations(List<PageTranslation> translations) =>
      this(translations: translations);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicPage(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicPage(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicPage call({
    Object? key = const $CopyWithPlaceholder(),
    Object? locale = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? body = const $CopyWithPlaceholder(),
    Object? assets = const $CopyWithPlaceholder(),
    Object? publishedAt = const $CopyWithPlaceholder(),
    Object? modifiedAt = const $CopyWithPlaceholder(),
    Object? translations = const $CopyWithPlaceholder(),
  }) {
    return PublicPage(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
      locale: locale == const $CopyWithPlaceholder()
          ? _value.locale
          // ignore: cast_nullable_to_non_nullable
          : locale as String,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      summary: summary == const $CopyWithPlaceholder()
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      body: body == const $CopyWithPlaceholder()
          ? _value.body
          // ignore: cast_nullable_to_non_nullable
          : body as Map<String, Object?>,
      assets: assets == const $CopyWithPlaceholder()
          ? _value.assets
          // ignore: cast_nullable_to_non_nullable
          : assets as Map<String, Map<String, Object?>>,
      publishedAt: publishedAt == const $CopyWithPlaceholder()
          ? _value.publishedAt
          // ignore: cast_nullable_to_non_nullable
          : publishedAt as DateTime,
      modifiedAt: modifiedAt == const $CopyWithPlaceholder()
          ? _value.modifiedAt
          // ignore: cast_nullable_to_non_nullable
          : modifiedAt as DateTime,
      translations: translations == const $CopyWithPlaceholder()
          ? _value.translations
          // ignore: cast_nullable_to_non_nullable
          : translations as List<PageTranslation>,
    );
  }
}

extension $PublicPageCopyWith on PublicPage {
  /// Returns a callable class that can be used as follows: `instanceOfPublicPage.copyWith(...)` or like so:`instanceOfPublicPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicPageCWProxy get copyWith => _$PublicPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPage _$PublicPageFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PublicPage',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'key',
        'locale',
        'path',
        'title',
        'summary',
        'body',
        'assets',
        'published_at',
        'modified_at',
        'translations',
      ],
    );
    final val = PublicPage(
      key: $checkedConvert('key', (v) => v as String),
      locale: $checkedConvert('locale', (v) => v as String),
      path: $checkedConvert('path', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      summary: $checkedConvert('summary', (v) => v as String),
      body: $checkedConvert('body', (v) => v as Map<String, dynamic>),
      assets: $checkedConvert(
        'assets',
        (v) => (v as Map<String, dynamic>).map(
          (k, e) => MapEntry(k, e as Map<String, dynamic>),
        ),
      ),
      publishedAt: $checkedConvert(
        'published_at',
        (v) => DateTime.parse(v as String),
      ),
      modifiedAt: $checkedConvert(
        'modified_at',
        (v) => DateTime.parse(v as String),
      ),
      translations: $checkedConvert(
        'translations',
        (v) => (v as List<dynamic>)
            .map((e) => PageTranslation.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'publishedAt': 'published_at',
    'modifiedAt': 'modified_at',
  },
);

Map<String, dynamic> _$PublicPageToJson(PublicPage instance) =>
    <String, dynamic>{
      'key': instance.key,
      'locale': instance.locale,
      'path': instance.path,
      'title': instance.title,
      'summary': instance.summary,
      'body': instance.body,
      'assets': instance.assets,
      'published_at': instance.publishedAt.toIso8601String(),
      'modified_at': instance.modifiedAt.toIso8601String(),
      'translations': instance.translations.map((e) => e.toJson()).toList(),
    };
