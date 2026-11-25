import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/telemetry/startup.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/adaptive/tab_header.dart';
import '../../ui/adaptive/tops.dart';
import '../../ui/components/signals.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/theme.dart';
import '../content/feed_slivers.dart';
import '../content/feeds.dart';
import '../content/list_screen.dart';
import 'front.dart';
import 'home_tabs.dart';

/// The name, a row of tabs, and the news. Each tab is a page that keeps its place.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin, GoesToTop {
  late TabController _tabs;
  late List<HomeTab> _list = ref.read(homeTabsProvider);
  final _scrolls = <String, ScrollController>{};
  final _gone = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _list.length, vsync: this)..addListener(_turned);
    ref
      ..listenManual(homeFeedProvider, (_, next) {
        if (next.hasValue) ref.read(startupProvider).drawn();
      }, fireImmediately: true)
      ..listenManual(homeTabsProvider, (_, next) => _retab(next));
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final s in _scrolls.values) {
      s.dispose();
    }
    _gone.dispose();
    super.dispose();
  }

  /// The sections arrived or changed: the reader stays in the page they are in.
  void _retab(List<HomeTab> next) {
    if (next.length == _list.length && next.indexed.every((e) => e.$2 == _list[e.$1])) return;
    final id = _list[_tabs.index].id;
    final at = next.indexWhere((x) => x.id == id);
    final old = _tabs;
    setState(() {
      _list = next;
      _tabs = TabController(
        length: next.length,
        initialIndex: at < 0 ? 0 : at,
        vsync: this,
        animationDuration: context.still ? Duration.zero : null,
      )..addListener(_turned);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  ScrollController _scrollOf(HomeTab tab) => _scrolls.putIfAbsent(tab.id, ScrollController.new);

  @override
  ScrollController get shown => _scrollOf(_list[_tabs.index]);

  double get _offset => shown.hasClients ? shown.offset : 0;

  /// A page at its top is never shown under a bar that has gone.
  void _turned() {
    final most = _offset.clamp(0.0, double.infinity);
    if (_gone.value > most) _gone.value = most;
  }

  bool _scrolled(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n is! ScrollUpdateNotification) return false;
    final most = TabHeader.collapses(context);
    final at = n.metrics.pixels.clamp(0.0, double.infinity);
    // Past either end the list is only being stretched.
    if (n.metrics.outOfRange && at > 0) return false;
    final next = (_gone.value + (n.scrollDelta ?? 0)).clamp(0.0, most);
    _gone.value = next > at ? at.clamp(0.0, most) : next;
    return false;
  }

  void _show(String id) {
    final at = _list.indexWhere((x) => x.id == id);
    if (at >= 0) _tabs.animateTo(at);
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final extent = TabHeader.extent(context);
    return Scaffold(
      body: Shimmer(
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _scrolled,
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final tab in _list)
                    _Page(
                      key: PageStorageKey(tab.id),
                      child: tab.feed == null
                          ? FrontPage(scroll: _scrollOf(tab), top: extent, gone: _gone, show: _show)
                          : _FeedPage(tab: tab, scroll: _scrollOf(tab), top: extent),
                    ),
                ],
              ),
            ),
            TabHeader(
              tabs: _tabs,
              labels: [
                for (final tab in _list) tab.name ?? (tab.feed == null ? s.forYou : s.latest),
              ],
              gone: _gone,
              onAgain: toTop,
            ),
          ],
        ),
      ),
    );
  }
}

/// Kept as it was while another page is read.
class _Page extends StatefulWidget {
  const _Page({super.key, required this.child});

  final Widget child;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _FeedPage extends ConsumerWidget {
  const _FeedPage({required this.tab, required this.scroll, required this.top});

  final HomeTab tab;
  final ScrollController scroll;
  final double top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = tab.feed!;
    final latest = feed.kind == FeedKind.latest;
    final now = ref.watch(clockNowProvider)();
    final breaking = !latest
        ? null
        : ref
              .watch(homeFeedProvider)
              .value
              ?.value
              .breaking
              .where((b) => b.isBreaking(now))
              .firstOrNull;
    final section = sectionOf(ref, feed);
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: 'home');
    return FeedPager(
      feed: feed,
      child: NewsScroll(
        controller: scroll,
        edge: top,
        onRefresh: () => ref.read(feedProvider(feed).notifier).refresh(),
        header: [TabHeaderRoom(height: top)],
        slivers: [
          if (breaking != null)
            SliverToBoxAdapter(
              child: BreakingBanner(story: breaking, onTap: () => open(breaking)),
            ),
          if (section != null && section.children.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.zero,
                child: FeedAboutHead(children: section.children),
              ),
            ),
          if (latest)
            ...feedSlivers(
              context,
              ref,
              feed: feed,
              open: open,
              place: 'latest',
              hide: {?breaking?.id},
            )
          else
            ...FeedBody.slivers(context, ref, feed: feed, place: 'tab-${tab.id}'),
        ],
      ),
    );
  }
}
