import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/network/loaded.dart';
import '../../core/providers.dart';

part 'feeds.g.dart';

/// Shows what is on the phone at once and asks for newer in the background. A failure keeps what is shown.
mixin CachedFirst<T> {
  Ref get ref;
  AsyncValue<Loaded<T>> get state;
  set state(AsyncValue<Loaded<T>> value);

  Call<T> get call;

  Future<Loaded<T>> start() async {
    final kept = await fromCache(call);
    if (kept == null) return fromNetwork(call);
    unawaited(Future(refresh));
    return kept;
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final fresh = await fromNetwork(call);
      if (ref.mounted) state = AsyncData(fresh);
    } on Failure catch (e) {
      if (!ref.mounted) return;
      state = switch (state) {
        AsyncData(:final value) => AsyncData(value.failed(e)),
        _ => AsyncError(e, StackTrace.current),
      };
    }
  }
}

@Riverpod(keepAlive: true)
class HomeFeed extends _$HomeFeed with CachedFirst<Home> {
  @override
  Call<Home> get call =>
      (x) => ref.read(contentApiProvider).home(locale: ref.read(localeNameProvider), extra: x);

  @override
  Future<Loaded<Home>> build() {
    ref.watch(localeNameProvider);
    return start();
  }
}

@Riverpod(keepAlive: true)
class Navigation extends _$Navigation with CachedFirst<List<NavigationItem>> {
  @override
  Call<List<NavigationItem>> get call =>
      (x) =>
          ref.read(contentApiProvider).navigation(locale: ref.read(localeNameProvider), extra: x);

  @override
  Future<Loaded<List<NavigationItem>>> build() {
    ref.watch(localeNameProvider);
    return start();
  }
}

/// One list of stories. The slug means what the kind says; types use the API's own names.
enum FeedKind { latest, type, category, tag, story, author }

@immutable
class FeedKey {
  const FeedKey(this.kind, this.slug, this.locale);

  final FeedKind kind;
  final String slug;
  final String locale;

  @override
  bool operator ==(Object other) =>
      other is FeedKey && other.kind == kind && other.slug == slug && other.locale == locale;
  @override
  int get hashCode => Object.hash(kind, slug, locale);
}

/// What the page is about, when it is about something.
@immutable
class FeedAbout {
  const FeedAbout({this.category, this.tag, this.story, this.author});

  final PublicCategoryDetail? category;
  final PublicLabel? tag;
  final PublicStory? story;
  final PublicAuthor? author;
}

@immutable
class FeedPageData {
  const FeedPageData(this.stories, this.next, [this.about = const FeedAbout()]);

  final List<Story> stories;
  final String? next;
  final FeedAbout about;
}

@immutable
class FeedState {
  const FeedState({
    required this.stories,
    required this.next,
    required this.at,
    this.about = const FeedAbout(),
    this.failure,
    this.loadingMore = false,
    this.moreFailed = false,
  });

  final List<Story> stories;
  final String? next;
  final DateTime at;
  final FeedAbout about;
  final Failure? failure;
  final bool loadingMore;
  final bool moreFailed;

  FeedState copyWith({
    List<Story>? stories,
    String? next,
    bool clearNext = false,
    Failure? failure,
    bool? loadingMore,
    bool? moreFailed,
  }) => FeedState(
    stories: stories ?? this.stories,
    next: clearNext ? null : next ?? this.next,
    at: at,
    about: about,
    failure: failure ?? this.failure,
    loadingMore: loadingMore ?? this.loadingMore,
    moreFailed: moreFailed ?? this.moreFailed,
  );
}

@riverpod
class Feed extends _$Feed {
  static const _page = 20;

  @override
  Future<FeedState> build(FeedKey key) async {
    final kept = await fromCache((x) => _ask(x, null));
    if (kept != null) {
      unawaited(Future(refresh));
      return _first(kept);
    }
    return _first(await fromNetwork((x) => _ask(x, null)));
  }

  FeedState _first(Loaded<FeedPageData> l) =>
      FeedState(stories: l.value.stories, next: l.value.next, at: l.at, about: l.value.about);

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final fresh = await fromNetwork((x) => _ask(x, null));
      if (ref.mounted) state = AsyncData(_first(fresh));
    } on Failure catch (e) {
      if (!ref.mounted) return;
      state = switch (state) {
        AsyncData(:final value) => AsyncData(value.copyWith(failure: e)),
        _ => AsyncError(e, StackTrace.current),
      };
    }
  }

  Future<void> loadMore() async {
    final now = state.value;
    if (now == null || now.next == null || now.loadingMore) return;
    state = AsyncData(now.copyWith(loadingMore: true, moreFailed: false));
    try {
      final page = await fromNetwork((x) => _ask(x, now.next));
      if (!ref.mounted) return;
      // Stories published meanwhile push others onto the next page: never show one twice.
      final seen = {for (final s in now.stories) s.id};
      state = AsyncData(
        now.copyWith(
          stories: [...now.stories, ...page.value.stories.where((s) => seen.add(s.id))],
          next: page.value.next,
          clearNext: page.value.next == null,
          loadingMore: false,
        ),
      );
    } on Failure {
      if (ref.mounted) state = AsyncData(now.copyWith(loadingMore: false, moreFailed: true));
    }
  }

  Future<Response<FeedPageData>> _ask(Map<String, dynamic> extra, String? cursor) async {
    final api = ref.read(contentApiProvider);
    final (slug, locale) = (key.slug, key.locale);
    Response<FeedPageData> wrap(Response<Object?> r, FeedPageData data) => Response(
      requestOptions: r.requestOptions,
      statusCode: r.statusCode,
      data: data,
      extra: r.extra,
    );
    switch (key.kind) {
      case FeedKind.latest:
        final r = await api.latest(locale: locale, cursor: cursor, limit: _page, extra: extra);
        return wrap(r, FeedPageData(r.data!.results, r.data!.nextCursor));
      case FeedKind.type:
        final r = await api.byType(
          kind: slug,
          locale: locale,
          cursor: cursor,
          limit: _page,
          extra: extra,
        );
        return wrap(r, FeedPageData(r.data!.results, r.data!.nextCursor));
      case FeedKind.category:
        final r = await api.category(
          slug: slug,
          locale: locale,
          cursor: cursor,
          limit: _page,
          extra: extra,
        );
        final d = r.data!;
        return wrap(r, FeedPageData(d.results, d.nextCursor, FeedAbout(category: d.category)));
      case FeedKind.tag:
        final r = await api.tag(
          slug: slug,
          locale: locale,
          cursor: cursor,
          limit: _page,
          extra: extra,
        );
        final d = r.data!;
        return wrap(r, FeedPageData(d.results, d.nextCursor, FeedAbout(tag: d.tag)));
      case FeedKind.story:
        final r = await api.story(
          slug: slug,
          locale: locale,
          cursor: cursor,
          limit: _page,
          extra: extra,
        );
        final d = r.data!;
        return wrap(r, FeedPageData(d.results, d.nextCursor, FeedAbout(story: d.story)));
      case FeedKind.author:
        final r = await api.author(
          slug: slug,
          locale: locale,
          cursor: cursor,
          limit: _page,
          extra: extra,
        );
        final d = r.data!;
        return wrap(r, FeedPageData(d.results, d.nextCursor, FeedAbout(author: d.author)));
    }
  }
}

/// Which article: its slug is unique within a language.
@riverpod
class ArticleOf extends _$ArticleOf with CachedFirst<Article> {
  @override
  Call<Article> get call =>
      (x) => ref.read(contentApiProvider).article(slug: slug, locale: locale, extra: x);

  @override
  Future<Loaded<Article>> build(String slug, String locale) => start();
}

@riverpod
Future<List<Story>> related(Ref ref, String slug, String locale) async {
  final api = ref.watch(contentApiProvider);
  Future<Response<Related>> call(Map<String, dynamic> x) =>
      api.related(slug: slug, locale: locale, extra: x);
  final kept = await fromCache(call);
  if (kept != null) return kept.value.results;
  return (await fromNetwork(call)).value.results;
}

/// Where an old address lives now, or null.
@riverpod
Future<String?> moved(Ref ref, String path) async {
  try {
    final r = await ref.watch(contentApiProvider).resolve(path: path);
    final to = r.data?.path;
    return to == null || to == path ? null : to;
  } on DioException {
    return null;
  }
}
