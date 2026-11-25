import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/router.dart';
import '../../core/config/app_config.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/adaptive/tops.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/theme.dart';
import '../content/feed_slivers.dart';
import '../content/feeds.dart';
import '../content/list_screen.dart' show FeedPager;
import 'shorts.dart';

part 'video_screen.g.dart';

/// Which half is shown, and which short to start from when one was tapped elsewhere.
@Riverpod(keepAlive: true)
class VideoTab extends _$VideoTab {
  String? first;

  @override
  int build() => ref.watch(flagsProvider.select((f) => f.shorts)) ? 0 : 1;

  void show(int tab, {String? first}) {
    this.first = first;
    state = tab;
    if (first != null) ref.read(startShortProvider.notifier).to(first);
  }
}

@Riverpod(keepAlive: true)
class StartShort extends _$StartShort {
  @override
  String? build() => null;

  void to(String id) => state = id;
  void done() => state = null;
}

class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key});

  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> with GoesToTop {
  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(videoTabProvider);
    final shorts = ref.watch(flagsProvider.select((f) => f.shorts));
    final s = Strings.of(context);
    final tabs = shorts
        ? TextTabs(
            labels: [s.shorts, s.longVideos],
            at: tab,
            onMedia: tab == 0,
            onChanged: (i) => ref.read(videoTabProvider.notifier).show(i),
          )
        : null;
    if (tab == 0) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayFor(OverMedia.ground),
        child: Shorts(header: tabs),
      );
    }
    return _Long(header: tabs, scroll: scroll);
  }
}

class _Long extends ConsumerWidget {
  const _Long({required this.header, required this.scroll});

  final Widget? header;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = FeedKey(FeedKind.type, 'video', ref.watch(localeNameProvider));
    final first = ref.watch(feedProvider(key)).value?.stories.firstOrNull;
    final loading = ref.watch(feedProvider(key)).value == null;
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: 'video');
    return Scaffold(
      body: Shimmer(
        child: FeedPager(
          feed: key,
          child: NewsScroll(
            controller: scroll,
            edge: MediaQuery.paddingOf(context).top + PlaceBar.extent,
            onRefresh: () => ref.read(feedProvider(key).notifier).refresh(),
            header: [PlaceBar(Strings.of(context).navVideo)],
            slivers: [
              if (header != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: NewsSpace.s2),
                    child: Align(alignment: Alignment.centerLeft, child: header),
                  ),
                ),
              if (loading || first != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
                    child: VideoCard(first, open: open, place: 'lead', large: true, lead: true),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s4)),
              ...feedSlivers(
                context,
                ref,
                feed: key,
                open: open,
                place: 'videos',
                skip: first == null ? 0 : 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
