import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../app/shell.dart';
import '../../app/window.dart';
import '../../core/config/app_config.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/network/loaded.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/signals.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/states/designed.dart';
import '../content/feed_slivers.dart';
import '../content/feeds.dart';
import '../system/banners.dart';
import '../video/video_screen.dart';
import 'carousel.dart';
import 'masthead.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    tabAgain[0].addListener(_top);
  }

  @override
  void dispose() {
    tabAgain[0].removeListener(_top);
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    if (!_scroll.hasClients) return;
    unawaited(
      _scroll.animateTo(
        0,
        duration: context.still ? const Duration(milliseconds: 1) : NewsMotion.slow * 2,
        curve: NewsMotion.standard,
      ),
    );
  }

  FeedKey get _latest => FeedKey(FeedKind.latest, '', ref.read(localeNameProvider));

  Future<void> _refresh() async {
    unawaited(HapticFeedback.mediumImpact());
    await Future.wait([
      ref.read(homeFeedProvider.notifier).refresh(),
      if (_tab == 1) ref.read(feedProvider(_latest).notifier).refresh(),
      ref.read(appConfigControllerProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeFeedProvider);
    final s = Strings.of(context);
    final loaded = home.value;
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: 'home');
    final now = ref.watch(clockNowProvider)();
    final breaking = loaded?.value.breaking.where((b) => b.isBreaking(now)).firstOrNull;
    return Scaffold(
      body: Shimmer(
        child: RefreshIndicator(
          onRefresh: _refresh,
          edgeOffset: MediaQuery.paddingOf(context).top + 92,
          color: context.colors.textPrimary,
          backgroundColor: context.colors.surfaceRaised,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (_tab == 1 && n.metrics.extentAfter < 1600) {
                unawaited(ref.read(feedProvider(_latest).notifier).loadMore());
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 900,
              slivers: [
                const HomeMasthead(),
                if (breaking != null)
                  SliverToBoxAdapter(
                    child: BreakingBanner(story: breaking, onTap: () => open(breaking)),
                  ),
                SliverToBoxAdapter(child: StaleBanner(loaded: loaded)),
                const SliverToBoxAdapter(child: UpdateBanner()),
                if (loaded == null || loaded.value.live.isNotEmpty)
                  SliverToBoxAdapter(
                    child: LiveRail(stories: loaded?.value.live, onTap: open),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NewsSpace.s5,
                      NewsSpace.s4,
                      NewsSpace.s5,
                      NewsSpace.s3,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Segmented(
                        labels: [s.forYou, s.latest],
                        at: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: CategoryChips()),
                const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s4)),
                if (_tab == 1)
                  ...feedSlivers(
                    context,
                    ref,
                    feed: _latest,
                    open: open,
                    place: 'latest',
                    hide: {?breaking?.id},
                  )
                else
                  ..._forYou(context, home, open, breaking),
                const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _forYou(
    BuildContext context,
    AsyncValue<Loaded<Home>> home,
    OpenStory open,
    Story? breaking,
  ) {
    final s = Strings.of(context);
    if (home case AsyncError(:final error) when home.value == null) {
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
    final h = home.value?.value;
    final lead = h?.lead.where((c) => c.id != breaking?.id).toList();
    final latest = h?.latest.where((c) => c.id != breaking?.id).toList();
    final List<Story?> top = lead?.skip(1).toList() ?? List.filled(3, null);
    final List<Story?> river = latest ?? List.filled(8, null);
    final window = windowOf(context);
    final compact = window == WindowClass.compact;
    final cover = lead == null ? null : lead.firstOrNull;
    Widget gap(double h) => SliverToBoxAdapter(child: SizedBox(height: h));
    return [
      if (h == null || cover != null)
        SliverToBoxAdapter(
          child: compact
              ? CoverCard(cover, open: open)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
                  child: SizedBox(
                    height: 460,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.bottomCenter,
                        maxHeight: double.infinity,
                        child: CoverCard(cover, open: open, radius: NewsRadius.xl),
                      ),
                    ),
                  ),
                ),
        ),
      if (top.isNotEmpty) ...[
        gap(NewsSpace.s8),
        SliverToBoxAdapter(child: SectionHead(s.topStories)),
        gap(NewsSpace.s1),
        SliverToBoxAdapter(
          child: TopStories(stories: top, open: open),
        ),
      ],
      gap(NewsSpace.s8),
      SliverToBoxAdapter(
        child: SectionHead(s.latest, more: s.more, onMore: () => setState(() => _tab = 1)),
      ),
      StorySliver(stories: river.take(5).toList(), open: open, place: 'river'),
      if (h == null || h.videos.isNotEmpty) ...[
        gap(NewsSpace.s6),
        SliverToBoxAdapter(
          child: _VideoBand(videos: h?.videos, shorts: h?.shorts, open: open),
        ),
      ],
      if (river.length > 5) ...[
        gap(NewsSpace.s4),
        StorySliver(stories: river.skip(5).take(6).toList(), open: open, place: 'river2'),
      ],
      for (final HomeSection section in h?.sections ?? const []) ...[
        gap(NewsSpace.s8),
        SliverToBoxAdapter(
          child: SectionHead(
            section.category.name,
            more: s.more,
            onMore: () => context.push(section.category.path),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
            child: StandardCard(
              section.results.first,
              open: open,
              place: 'section-${section.category.id}',
              ratio: compact ? 16 / 10 : 21 / 9,
            ),
          ),
        ),
        gap(NewsSpace.s2),
        StorySliver(
          stories: section.results.skip(1).take(3).toList(),
          open: open,
          place: 'section-${section.category.id}',
        ),
      ],
    ];
  }
}

/// The sections, one tap away.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final items = nav.value?.value;
    if (items == null && nav.hasError) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
      child: Row(
        children: [
          if (items == null)
            for (final w in const [84.0, 76.0, 104.0, 92.0])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Bone(width: w, height: 48, radius: 28),
              )
          else
            for (final n in items)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NewsChip(n.name, onTap: () => context.push(n.path)),
              ),
        ],
      ),
    );
  }
}

/// Moving pictures, on their own ground.
class _VideoBand extends ConsumerWidget {
  const _VideoBand({required this.videos, required this.shorts, required this.open});

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

    final scale = (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1.0, 2.0);
    return Container(
      color: context.colors.surfaceSunken,
      padding: const EdgeInsets.symmetric(vertical: NewsSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(s.videos, more: s.more, onMore: () => toVideo(1)),
          const SizedBox(height: NewsSpace.s1),
          SizedBox(
            height: 174 + 110 * scale,
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
