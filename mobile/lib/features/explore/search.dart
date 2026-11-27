import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';

/// A kind of story a reader picks; the API is asked for its types (the website's `KINDS`, ADR-0049).
enum SearchKind {
  all(null),
  stories('article,breaking,opinion'),
  videos('video,youtube,short'),
  live('live_blog,live_stream'),
  galleries('gallery');

  const SearchKind(this.types);
  final String? types;
}

/// How far back: the API's own values.
enum SearchSince {
  any(null),
  day('24h'),
  week('7d'),
  month('30d'),
  year('1y');

  const SearchSince(this.value);
  final String? value;
}

/// One question: the words and the filters. Equal questions share one answer.
@immutable
class SearchAsk {
  const SearchAsk(
    this.q, {
    this.newest = false,
    this.kind = SearchKind.all,
    this.since = SearchSince.any,
  });

  final String q;
  final bool newest;
  final SearchKind kind;
  final SearchSince since;

  bool get filtered => newest || kind != SearchKind.all || since != SearchSince.any;

  SearchAsk copyWith({String? q, bool? newest, SearchKind? kind, SearchSince? since}) => SearchAsk(
    q ?? this.q,
    newest: newest ?? this.newest,
    kind: kind ?? this.kind,
    since: since ?? this.since,
  );

  @override
  bool operator ==(Object other) =>
      other is SearchAsk &&
      other.q == q &&
      other.newest == newest &&
      other.kind == kind &&
      other.since == since;

  @override
  int get hashCode => Object.hash(q, newest, kind, since);
}

/// What came back so far, and whether there is more.
@immutable
class Found {
  const Found({
    required this.hits,
    required this.total,
    required this.exact,
    required this.next,
    required this.available,
    this.more = false,
  });

  final List<SearchHit> hits;
  final int total;
  final bool exact;
  final String? next;
  final bool available;

  /// The next page is being asked for.
  final bool more;
}

/// The results of one question, a page at a time. Never cached on the phone: a search is asked of the server.
class SearchResults extends AsyncNotifier<Found> {
  SearchResults(this.ask);

  final SearchAsk ask;

  Future<Search> _page(String? cursor) async {
    try {
      final r = await ref
          .read(contentApiProvider)
          .search(
            q: ask.q,
            locale: ref.read(localeNameProvider),
            sort: ask.newest ? 'newest' : 'relevance',
            type: ask.kind.types,
            since: ask.since.value,
            cursor: cursor,
          );
      return r.data!;
    } on Object catch (e) {
      throw Failure.from(e);
    }
  }

  @override
  Future<Found> build() async {
    ref.watch(localeNameProvider);
    final p = await _page(null);
    return Found(
      hits: p.results,
      total: p.total,
      exact: p.totalIsExact,
      next: p.nextCursor,
      available: p.available,
    );
  }

  Future<void> more() async {
    final now = state.value;
    if (now == null || now.next == null || now.more) return;
    state = AsyncData(_with(now, more: true));
    try {
      final p = await _page(now.next);
      if (!ref.mounted) return;
      state = AsyncData(
        Found(
          hits: [...now.hits, ...p.results],
          total: now.total,
          exact: now.exact,
          next: p.nextCursor,
          available: now.available,
        ),
      );
    } on Failure {
      // What is shown stays; the reader can scroll again.
      if (ref.mounted) state = AsyncData(_with(now, more: false));
    }
  }

  static Found _with(Found f, {required bool more}) => Found(
    hits: f.hits,
    total: f.total,
    exact: f.exact,
    next: f.next,
    available: f.available,
    more: more,
  );
}

final searchResultsProvider = AsyncNotifierProvider.autoDispose
    .family<SearchResults, Found, SearchAsk>(SearchResults.new);

/// Headlines for the words typed so far (the app's suggestions; the website shows results instead).
final searchSuggestProvider = FutureProvider.autoDispose.family<List<Suggestion>, String>((
  ref,
  q,
) async {
  // Words typed in quick succession: only the last is asked (300 ms after the last key).
  var gone = false;
  ref.onDispose(() => gone = true);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  if (gone) return const [];
  final cancel = CancelToken();
  ref.onDispose(cancel.cancel);
  try {
    final r = await ref
        .read(contentApiProvider)
        .searchSuggest(q: q, locale: ref.read(localeNameProvider), cancelToken: cancel);
    return r.data?.results ?? const [];
  } on DioException {
    return const []; // suggestions are a help, never an error
  }
});

/// The searches made on this phone, newest first; kept on the phone only, never sent anywhere.
class RecentSearches extends AsyncNotifier<List<String>> {
  static const key = 'recentSearches';
  static const keep = 8;

  @override
  Future<List<String>> build() async {
    final raw = (await ref.read(databaseProvider).allPrefs())[key];
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).cast<String>();
    } on Object {
      return const [];
    }
  }

  Future<void> add(String q) async {
    final words = q.trim();
    if (words.isEmpty) return;
    final now = state.value ?? await future;
    final next = [
      words,
      ...now.where((w) => w.toLowerCase() != words.toLowerCase()),
    ].take(keep).toList();
    state = AsyncData(next);
    await ref.read(databaseProvider).putPref(key, jsonEncode(next));
  }

  Future<void> clear() async {
    state = const AsyncData([]);
    await ref.read(databaseProvider).putPref(key, '[]');
  }
}

final recentSearchesProvider = AsyncNotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

/// The shortest words the server answers.
const searchMinimum = 2;

/// Searches made, recent ones to pick from (the field is empty and has focus).
class RecentList extends ConsumerWidget {
  const RecentList({super.key, required this.pick});

  final ValueChanged<String> pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final recent = ref.watch(recentSearchesProvider).value ?? const [];
    if (recent.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(NewsSpace.s5, NewsSpace.s2, NewsSpace.s2, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.searchRecent,
                    style: context.type.label.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(ref.read(recentSearchesProvider.notifier).clear()),
                child: Text(s.searchClearRecent),
              ),
            ],
          ),
        ),
        for (final words in recent)
          Pressable(
            label: words,
            onTap: () => pick(words),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5, vertical: 12),
              child: Row(
                children: [
                  NewsIcon(NewsIcons.history, size: 18, color: c.textSecondary),
                  const SizedBox(width: NewsSpace.s3),
                  Expanded(
                    child: Text(
                      words,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.bodyM.copyWith(color: c.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Headlines while typing: one tap opens the story.
class SuggestList extends ConsumerWidget {
  const SuggestList(this.words, {super.key});

  final String words;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final found = ref.watch(searchSuggestProvider(words)).value ?? const [];
    return SliverList.list(
      children: [
        for (final x in found)
          Pressable(
            link: true,
            label: x.headline,
            onTap: () => openPath(context, x.path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5, vertical: 12),
              child: Row(
                children: [
                  NewsIcon(NewsIcons.search, size: 18, color: c.textSecondary),
                  const SizedBox(width: NewsSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          x.headline,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.bodyM.copyWith(color: c.textPrimary),
                        ),
                        if (x.category.isNotEmpty)
                          Text(
                            x.category,
                            style: context.type.caption.copyWith(color: c.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The filters: order, kind and time, as chips that open a short list.
class SearchFilters extends StatelessWidget {
  const SearchFilters({super.key, required this.ask, required this.change});

  final SearchAsk ask;
  final ValueChanged<SearchAsk> change;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    String kindName(SearchKind k) => switch (k) {
      SearchKind.all => s.searchTypeAll,
      SearchKind.stories => s.searchTypeStories,
      SearchKind.videos => s.searchTypeVideos,
      SearchKind.live => s.searchTypeLive,
      SearchKind.galleries => s.searchTypeGalleries,
    };
    String sinceName(SearchSince x) => switch (x) {
      SearchSince.any => s.searchAnyTime,
      SearchSince.day => s.searchPastDay,
      SearchSince.week => s.searchPastWeek,
      SearchSince.month => s.searchPastMonth,
      SearchSince.year => s.searchPastYear,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
      child: Row(
        spacing: NewsSpace.s2,
        children: [
          _Choice<bool>(
            label: s.searchSort,
            value: ask.newest,
            on: ask.newest,
            options: {false: s.searchSortBest, true: s.searchSortNewest},
            pick: (v) => change(ask.copyWith(newest: v)),
          ),
          _Choice<SearchKind>(
            label: s.searchType,
            value: ask.kind,
            on: ask.kind != SearchKind.all,
            options: {for (final k in SearchKind.values) k: kindName(k)},
            pick: (v) => change(ask.copyWith(kind: v)),
          ),
          _Choice<SearchSince>(
            label: s.searchWhen,
            value: ask.since,
            on: ask.since != SearchSince.any,
            options: {for (final x in SearchSince.values) x: sinceName(x)},
            pick: (v) => change(ask.copyWith(since: v)),
          ),
        ],
      ),
    );
  }
}

class _Choice<T> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.value,
    required this.on,
    required this.options,
    required this.pick,
  });

  final String label;
  final T value;
  final bool on;
  final Map<T, String> options;
  final ValueChanged<T> pick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<T>(
      tooltip: label,
      initialValue: value,
      onSelected: pick,
      itemBuilder: (_) => [
        for (final MapEntry(:key, :value) in options.entries)
          CheckedPopupMenuItem<T>(value: key, checked: key == this.value, child: Text(value)),
      ],
      child: Semantics(
        button: true,
        label: '$label: ${options[value]}',
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? c.brand : c.surfaceSunken,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                options[value]!,
                style: context.type.label.copyWith(color: on ? c.onBrand : c.textPrimary),
              ),
              const SizedBox(width: 4),
              NewsIcon(NewsIcons.chevronDown, size: 16, color: on ? c.onBrand : c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The results of a question: how many, the stories with what matched in bold, more as one scrolls.
class SearchResultsList extends ConsumerWidget {
  const SearchResultsList({super.key, required this.ask, required this.clearFilters});

  final SearchAsk ask;
  final VoidCallback clearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final answer = ref.watch(searchResultsProvider(ask));
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: 'search');
    final found = answer.value;
    if (found == null) {
      if (answer.hasError) {
        return SliverToBoxAdapter(
          child: Designed.failure(
            context,
            answer.error!,
            retry: () => ref.invalidate(searchResultsProvider(ask)),
          ),
        );
      }
      return SliverList.builder(
        itemCount: 5,
        itemBuilder: (_, _) => RowCard(null, open: open, place: 'search'),
      );
    }
    if (!found.available) {
      return SliverToBoxAdapter(
        child: Designed(drawing: Drawing.error, title: s.search, body: s.searchUnavailable),
      );
    }
    if (found.hits.isEmpty) {
      return SliverToBoxAdapter(
        child: Designed(
          drawing: Drawing.empty,
          title: s.searchNoneTitle,
          body: s.searchNoneBody,
          action: ask.filtered ? s.searchFilters : null,
          onAction: ask.filtered ? clearFilters : null,
        ),
      );
    }
    return SliverList.builder(
      itemCount: found.hits.length + 2,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                NewsSpace.s5,
                NewsSpace.s3,
                NewsSpace.s5,
                NewsSpace.s2,
              ),
              child: Text(
                found.exact ? s.searchCount(found.total) : s.searchCountMany(found.total),
                style: context.type.caption.copyWith(color: c.textSecondary),
              ),
            ),
          );
        }
        if (i == found.hits.length + 1) {
          if (found.next == null) return const SizedBox(height: NewsSpace.s10);
          // The end of the list asks for the next page as it comes into view.
          scheduleMicrotask(() => ref.read(searchResultsProvider(ask).notifier).more());
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: NewsSpace.s3),
            child: RowCard(null, open: _none, place: 'search'),
          );
        }
        final hit = found.hits[i - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RowCard(hit.card, open: open, place: 'search'),
            if (hit.snippet.isNotEmpty) Snippet(hit.snippet),
          ],
        );
      },
    );
  }
}

void _none(Story _, {String? heroTag}) {}

/// Where the words were found: text, with the matched words in bold. Never markup.
class Snippet extends StatelessWidget {
  const Snippet(this.parts, {super.key});

  final List<Segment> parts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = context.type.caption.copyWith(color: c.textSecondary, height: 1.4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(NewsSpace.s5, 0, NewsSpace.s5, NewsSpace.s3),
      child: Text.rich(
        TextSpan(
          children: [
            for (final p in parts)
              TextSpan(
                text: p.text,
                style: p.hit
                    ? base.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)
                    : null,
              ),
          ],
        ),
        style: base,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
