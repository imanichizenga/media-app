import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_api_client/news_api_client.dart' as api;
import 'package:news_content/news_content.dart' hide Block;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/network/images.dart';
import '../../core/network/loaded.dart';
import '../../core/providers.dart';
import '../../core/storage/database.dart';
import '../../core/telemetry/analytics.dart';

part 'library.g.dart';

/// The device library: saved articles with their pictures, and what was read. Joins the account in M4.
@immutable
class SavedStory {
  const SavedStory(this.story, {required this.ready, required this.at});

  final Story story;

  /// The text and every picture are on the phone.
  final bool ready;
  final DateTime at;
}

@immutable
class ReadStory {
  const ReadStory(this.story, {required this.percent, required this.at});

  final Story story;
  final int percent;
  final DateTime at;
}

Story? _story(String json) {
  try {
    return api.Card.fromJson(jsonDecode(json) as Map<String, dynamic>);
  } on Object {
    return null; // kept by an older version, in a shape this one does not know
  }
}

@Riverpod(keepAlive: true)
Stream<List<SavedStory>> savedStories(Ref ref) => ref
    .watch(databaseProvider)
    .watchSaved()
    .map(
      (rows) => [
        for (final r in rows)
          if (_story(r.card) case final story?)
            SavedStory(story, ready: r.article != null && r.imagesReady, at: r.savedAt),
      ],
    );

@Riverpod(keepAlive: true)
Stream<List<ReadStory>> historyStories(Ref ref) => ref
    .watch(databaseProvider)
    .watchHistory()
    .map(
      (rows) => [
        for (final r in rows)
          if (_story(r.card) case final story?)
            ReadStory(story, percent: r.percent, at: r.openedAt),
      ],
    );

@riverpod
bool isSaved(Ref ref, String path) =>
    ref.watch(savedStoriesProvider).value?.any((s) => s.story.path == path) ?? false;

/// The saved copy, for reading without a connection.
@riverpod
Future<Article?> savedArticle(Ref ref, String path) async {
  final row = await ref.watch(databaseProvider).saved(path);
  if (row?.article == null) return null;
  try {
    return Article.fromJson(jsonDecode(row!.article!) as Map<String, dynamic>);
  } on Object {
    return null;
  }
}

@Riverpod(keepAlive: true)
class Library extends _$Library {
  @override
  void build() {}

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> save(Story story, {Article? article}) async {
    ref.read(analyticsProvider).track(StorySaved(story.id, saved: true));
    await _db.putSaved(
      SavedArticlesCompanion.insert(
        path: story.path,
        card: jsonEncode(story.toJson()),
        article: Value(article == null ? null : jsonEncode(article.toJson())),
        savedAt: DateTime.now(),
      ),
    );
    await download(story.path, story.slug, story.locale, article);
  }

  /// The text, then every picture it shows. What fails is tried again on the next start.
  Future<void> download(String path, String slug, String locale, Article? known) async {
    try {
      final article =
          known ??
          (await fromNetwork(
            (x) => ref.read(contentApiProvider).article(slug: slug, locale: locale, extra: x),
          )).value;
      if (await _db.saved(path) == null) return; // removed meanwhile
      await _db.completeSaved(path, article: jsonEncode(article.toJson()));
      await Future.wait(picturesOf(article).map(ref.read(pictureKeeperProvider).keep));
      await _db.completeSaved(path, imagesReady: true);
    } on Exception catch (e) {
      if (e is! Failure) debugPrint('$e');
    }
  }

  Future<void> resumeDownloads() async {
    for (final s in await ref.read(savedStoriesProvider.future)) {
      if (!s.ready) await download(s.story.path, s.story.slug, s.story.locale, null);
    }
  }

  /// At the sizes the article shows them, and at the size of the list.
  Iterable<String> picturesOf(Article a) {
    final pictures = ref.read(picturesProvider.notifier);
    String at(PublicImage i, double w) => pictures.url(i, w);
    return {
      if (a.image case final hero?) ...[at(hero, 1280), at(hero, 320)],
      for (final raw in a.assets.values)
        if (raw['kind'] == 'image')
          at(PublicImage.fromJson(raw), 1280)
        else if (raw['kind'] == 'video')
          pictures.address(raw['poster'] as String),
      for (final b in a.authors)
        if (b.avatar case final face?) at(face, 320),
    }.where((u) => u.isNotEmpty);
  }

  Future<void> unsave(Story story) async {
    ref.read(analyticsProvider).track(StorySaved(story.id, saved: false));
    final copy = await ref.read(savedArticleProvider(story.path).future);
    await _db.unsave(story.path);
    if (copy != null) {
      for (final url in picturesOf(copy)) {
        unawaited(ref.read(pictureKeeperProvider).drop(url));
      }
    }
  }

  Future<void> opened(Story story) => _db.opened(story.path, jsonEncode(story.toJson()));
  Future<void> readTo(Story story, int percent) => _db.readTo(story.path, percent);
  Future<void> clearHistory() => _db.clearHistory();
}

/// A card for an article that was opened by its address.
Story storyOf(Article a) => api.Card(
  id: a.id,
  type: a.type,
  locale: a.locale,
  path: a.path,
  slug: a.slug,
  headline: a.headline,
  standfirst: a.standfirst,
  category: a.category,
  authors: [
    for (final b in a.authors) CardByline(id: b.id, name: b.name, slug: b.slug, path: b.path),
  ],
  image: a.image,
  video: a.video,
  youtubeId: a.youtubeId,
  durationMs: a.durationMs,
  readingMinutes: a.readingMinutes,
  publishedAt: a.publishedAt,
  modifiedAt: a.modifiedAt,
  isSensitive: a.isSensitive,
  breakingUntil: a.breakingUntil,
  isLive: a.isLive,
);

ContentDocument documentOf(Article a) => ContentDocument.fromJson(a.body.cast<String, dynamic>());
