import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../app/window.dart';
import '../../core/config/app_config.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/network/loaded.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/adaptive/tab_header.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/signals.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../content/feed_slivers.dart';
import '../content/feeds.dart';
import '../saved/library.dart';
import '../system/banners.dart';
import '../video/video_screen.dart';
import 'carousel.dart';

/// The front page. What was refreshed is shown to a reader at the top; further down nothing moves until they ask (V2).
class FrontPage extends ConsumerStatefulWidget {
  const FrontPage({
    super.key,
    required this.scroll,
    required this.top,
    required this.gone,
    required this.show,
  });

  final ScrollController scroll;
  final double top;
  final ValueListenable<double> gone;

  /// Turns to another page of Home.
  final ValueChanged<String> show;

  @override
  ConsumerState<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends ConsumerState<FrontPage> {
  Loaded<Home>? _shown;
  String? _locale;
  bool _waiting = false;

  /// Stories have been on the screen: what comes now may grow in, what came with them may not.
  bool _settled = false;

  bool get _atTop => !widget.scroll.hasClients || widget.scroll.offset <= 8;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_moved);
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_moved);
    super.dispose();
  }

  void _moved() {
    if (_waiting && _atTop) setState(() {});
  }

  static List<String> _stories(Home h) => [
    for (final list in [h.breaking, h.live, h.lead, h.latest, h.videos])
      for (final x in list) '${x.id}${x.headline}',
  ];

  /// What to draw: the newest, unless that would move what is being read.
  Loaded<Home>? _settle(Loaded<Home>? next, String locale) {
    final old = _shown;
    final keep =
        old != null &&
        next != null &&
        _locale == locale &&
        !_atTop &&
        !listEquals(_stories(old.value), _stories(next.value));
    _waiting = keep;
    _locale = locale;
    return _shown = keep ? old : next;
  }

  void _news() {
    unawaited(
      widget.scroll.animateTo(
        0,
        duration: context.still ? const Duration(milliseconds: 1) : NewsMotion.slow * 2,
        curve: NewsMotion.standard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeFeedProvider);
    final loaded = _settle(home.value, ref.watch(localeNameProvider));
    final s = Strings.of(context);
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: 'home');
    final now = ref.watch(clockNowProvider)();
    final breaking = loaded?.value.breaking.where((b) => b.isBreaking(now)).firstOrNull;
    final live = loaded?.value.live ?? const <Story>[];
    if (loaded != null && !_settled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _settled = true);
    }
    Widget grows(Widget child) => SliverToBoxAdapter(
      child: !_settled
          ? child
          : AnimatedSize(
              duration: context.still ? const Duration(milliseconds: 1) : NewsMotion.slow,
              curve: NewsMotion.standard,
              alignment: Alignment.topCenter,
              child: SizedBox(width: double.infinity, child: child),
            ),
    );
    return Stack(
      children: [
        NewsScroll(
          controller: widget.scroll,
          edge: widget.top,
          onRefresh: () => Future.wait([
            ref.read(homeFeedProvider.notifier).refresh(),
            ref.read(appConfigControllerProvider.notifier).refresh(),
          ]),
          header: [TabHeaderRoom(height: widget.top)],
          slivers: [
            grows(
              breaking == null
                  ? const SizedBox.shrink()
                  : BreakingBanner(story: breaking, onTap: () => open(breaking)),
            ),
            SliverToBoxAdapter(child: StaleBanner(loaded: loaded)),
            const SliverToBoxAdapter(child: UpdateBanner()),
            grows(
              LiveRail(
                live: loaded == null ? null : live,
                // The day's stories after the live ones: the lead, then the newest, each once, with a picture.
                stories: [
                  for (final (i, x) in [...?loaded?.value.lead, ...?loaded?.value.latest].indexed)
                    if (x.image != null &&
                        [
                              ...?loaded?.value.lead,
                              ...?loaded?.value.latest,
                            ].indexWhere((y) => y.id == x.id) ==
                            i)
                      x,
                ].take(14).toList(),
                seen: {
                  for (final r in ref.watch(historyStoriesProvider).value ?? const <ReadStory>[])
                    r.story.path,
                },
                onTap: open,
              ),
            ),
            ..._body(context, home, loaded?.value, open, breaking, s),
          ],
        ),
        if (_waiting)
          ValueListenableBuilder(
            valueListenable: widget.gone,
            builder: (context, gone, child) =>
                Positioned(top: widget.top - gone + 12, left: 0, right: 0, child: child!),
            child: Center(child: _NewsPill(s.newStories, onTap: _news)),
          ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    AsyncValue<Loaded<Home>> home,
    Home? h,
    OpenStory open,
    Story? breaking,
    Strings s,
  ) {
    if (home case AsyncError(:final error) when h == null) {
      return [
        SliverToBoxAdapter(
          child: Designed.failure(
            context,
            error,
            retry: () => ref.invalidate(homeFeedProvider),
            saved: error is OfflineFailure ? () => const SavedRoute().go(context) : null,
          ),
        ),
      ];
    }
    final lead = h?.lead.where((c) => c.id != breaking?.id).toList();
    final latest = h?.latest.where((c) => c.id != breaking?.id).toList();
    final List<Story?> top = lead?.skip(1).toList() ?? List.filled(3, null);
    final List<Story?> river = latest ?? List.filled(8, null);
    final window = windowOf(context);
    final compact = window == WindowClass.compact;
    final wide = window == WindowClass.expanded;
    final cover = lead?.firstOrNull;
    final columns = switch (window) {
      WindowClass.compact => 1,
      WindowClass.medium => 2,
      WindowClass.expanded => 3,
    };
    const side = EdgeInsets.symmetric(horizontal: NewsSpace.s5);
    Widget gap(double h) => SliverToBoxAdapter(child: SizedBox(height: h));
    // Beside the lead on a wide screen, and then not again below.
    final beside = wide ? 4 : 0;
    final below = river.skip(beside).toList();
    final first = compact ? 5 : columns * 2;
    return [
      if (h == null || cover != null)
        SliverToBoxAdapter(
          child: compact
              ? CoverCard(cover, open: open)
              : Padding(
                  padding: side.copyWith(top: NewsSpace.s4),
                  child: !wide
                      ? CoverCard(cover, open: open, radius: NewsRadius.xl, ratio: 2)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: CoverCard(
                                cover,
                                open: open,
                                radius: NewsRadius.xl,
                                ratio: 4 / 3,
                              ),
                            ),
                            const SizedBox(width: NewsSpace.s6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHead(
                                    s.latest,
                                    padded: false,
                                    more: s.more,
                                    onMore: () => widget.show('latest'),
                                  ),
                                  for (final (i, story) in river.take(beside).indexed) ...[
                                    if (i > 0) const Divider(),
                                    CompactCard(story, open: open),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
        ),
      if (top.isNotEmpty) ...[
        gap(NewsSpace.s5),
        SliverToBoxAdapter(child: SectionHead(s.topStories)),
        SliverToBoxAdapter(
          child: TopStories(stories: top, open: open),
        ),
      ],
      gap(NewsSpace.s6),
      if (!wide)
        SliverToBoxAdapter(
          child: SectionHead(s.latest, more: s.more, onMore: () => widget.show('latest')),
        ),
      StorySliver(stories: below.take(first).toList(), open: open, place: 'river'),
      if (h == null || h.videos.isNotEmpty) ...[
        gap(NewsSpace.s6),
        SliverToBoxAdapter(
          child: VideoBand(videos: h?.videos, shorts: h?.shorts, open: open),
        ),
      ],
      if (below.length > first) ...[
        gap(NewsSpace.s4),
        StorySliver(stories: below.skip(first).take(6).toList(), open: open, place: 'river2'),
      ],
      for (final HomeSection section in h?.sections ?? const []) ...[
        gap(NewsSpace.s6),
        SliverToBoxAdapter(
          child: SectionHead(
            section.category.name,
            more: s.more,
            onMore: () => widget.show(section.category.id),
          ),
        ),
        if (compact) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: side,
              child: StandardCard(
                section.results.first,
                open: open,
                place: 'section-${section.category.id}',
              ),
            ),
          ),
          gap(NewsSpace.s2),
        ],
        StorySliver(
          stories: section.results.skip(compact ? 1 : 0).take(compact ? 3 : columns * 2).toList(),
          open: open,
          place: 'section-${section.category.id}',
          whole: true,
        ),
      ],
    ];
  }
}

/// Says that there is news above, and goes there.
class _NewsPill extends StatelessWidget {
  const _NewsPill(this.text, {required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: c.textPrimary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: OverMedia.shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NewsIcon(NewsIcons.arrowUp, size: 16, color: c.bg),
                const SizedBox(width: 8),
                Text(text, style: context.type.label.copyWith(color: c.bg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Moving pictures, on their own ground.
class VideoBand extends ConsumerWidget {
  const VideoBand({super.key, required this.videos, required this.shorts, required this.open});

  final List<Story>? videos;
  final List<Story>? shorts;
  final OpenStory open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final List<Story?> clips = videos?.take(8).toList() ?? List.filled(2, null);
    final List<Story?> vertical = !ref.watch(flagsProvider).shorts
        ? const []
        : shorts?.take(10).toList() ?? List.filled(4, null);
    void toVideo(int tab, [String? first]) {
      ref.read(videoTabProvider.notifier).show(tab, first: first);
      const VideoRoute().go(context);
    }

    return Container(
      color: context.colors.surfaceSunken,
      padding: const EdgeInsets.symmetric(vertical: NewsSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(s.videos, more: s.more, onMore: () => toVideo(1)),
          const SizedBox(height: NewsSpace.s1),
          SizedBox(
            height: VideoCard.stripHeight(context, 296),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
              itemCount: clips.length,
              separatorBuilder: (_, _) => const SizedBox(width: NewsSpace.s4),
              itemBuilder: (_, i) => SizedBox(
                width: 296,
                child: VideoCard(clips[i], open: open, place: 'strip'),
              ),
            ),
          ),
          if (vertical.isNotEmpty) ...[
            const SizedBox(height: NewsSpace.s4),
            SectionHead(s.shorts, more: s.more, onMore: () => toVideo(0)),
            const SizedBox(height: NewsSpace.s1),
            SizedBox(
              height: 266,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
                itemCount: vertical.length,
                separatorBuilder: (_, _) => const SizedBox(width: NewsSpace.s3),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.4,
                    child: ShortCard(vertical[i], onTap: () => toVideo(0, vertical[i]?.id)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
