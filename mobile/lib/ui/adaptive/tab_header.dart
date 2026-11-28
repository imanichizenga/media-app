import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../l10n/gen/strings.dart';
import '../components/basics.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';
import 'adaptive.dart';

/// The name over a row of tabs. The name gives way as one reads, the tabs stay (S1, N3).
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.tabs,
    required this.labels,
    required this.gone,
    required this.onAgain,
  });

  final TabController tabs;
  final List<String> labels;

  /// How much of the bar has scrolled away.
  final ValueListenable<double> gone;

  /// The tab one is in, tapped.
  final VoidCallback onAgain;

  static const row = 48.0;
  static const bar = 56.0;

  /// iOS keeps a compact bar, Android lets it go.
  static double collapses(BuildContext context) => context.isApple ? bar - 44 : bar;

  static double extent(BuildContext context) => MediaQuery.paddingOf(context).top + bar + row;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final most = collapses(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.mastheadBg),
      child: ValueListenableBuilder(
        valueListenable: gone,
        builder: (context, away, child) {
          final t = most == 0 ? 0.0 : (away / most).clamp(0.0, 1.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BarGround(
                color: c.mastheadBg,
                bottom: BorderSide(color: c.mastheadRule, width: 2),
                child: SizedBox(
                  height: top + bar - away,
                  width: double.infinity,
                  child: ClipRect(
                    child: Padding(
                      padding: EdgeInsets.only(top: top),
                      child: Stack(
                        children: [
                          Positioned.fill(child: _name(context, t)),
                          // Search, at the top of Home: what readers come back for (ADR-0051).
                          Positioned(
                            right: NewsSpace.s2,
                            top: 0,
                            bottom: 0,
                            child: Opacity(
                              opacity: (1 - t * 1.4).clamp(0, 1),
                              child: Center(
                                child: RoundButton(
                                  NewsIcons.search,
                                  label: Strings.of(context).searchOpen,
                                  onTap: () => GoRouter.of(context).go('/search?focus=1'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: BarGround(
          color: c.bg,
          bottom: BorderSide(color: c.border, width: 0.5),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: SizedBox(
              height: row,
              width: double.infinity,
              child: Material(
                color: OverMedia.clear,
                child: MoreTabs(
                  child: TabBar(
                    controller: tabs,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    dividerColor: OverMedia.clear,
                    dividerHeight: 0,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(color: activeOnPage(c), width: 3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    labelColor: c.textPrimary,
                    unselectedLabelColor: c.textSecondary,
                    labelStyle: context.type.title.copyWith(fontSize: 15),
                    unselectedLabelStyle: context.type.title.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontVariations: const [FontVariation('wght', 500)],
                    ),
                    overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.05)),
                    onTap: (i) {
                      if (!tabs.indexIsChanging) onAgain();
                    },
                    tabs: [for (final l in labels) Tab(height: row - 1, text: l)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _name(BuildContext context, double t) {
    const side = EdgeInsets.symmetric(horizontal: NewsSpace.s5);
    Widget word(double size) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Semantics(header: true, child: Wordmark(size: size)),
    );
    // Large at the start, then small in the middle: iOS's large title, at the height of a bar.
    if (context.isApple) {
      return Padding(
        padding: side,
        child: Align(
          alignment: Alignment.lerp(Alignment.centerLeft, Alignment.center, t)!,
          child: word(28 - 8 * t),
        ),
      );
    }
    return OverflowBox(
      alignment: Alignment.bottomCenter,
      minHeight: bar - 2,
      maxHeight: bar - 2,
      child: Opacity(
        opacity: (1 - t * 1.4).clamp(0, 1),
        child: Padding(
          padding: side,
          child: Align(alignment: Alignment.centerLeft, child: word(26)),
        ),
      ),
    );
  }
}

/// The room the header takes at the top of each page. Pinned, so that iOS's refresh appears beneath the header and not
/// behind it.
class TabHeaderRoom extends StatelessWidget {
  const TabHeaderRoom({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) =>
      SliverPersistentHeader(pinned: true, delegate: _Room(height));
}

class _Room extends SliverPersistentHeaderDelegate {
  const _Room(this.height);

  final double height;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrink, bool overlaps) => const SizedBox.expand();
  @override
  bool shouldRebuild(_Room old) => old.height != height;
}

/// A row of tabs that says when it has more than it shows: the side with more fades out, so the next tab peeks in, and
/// a chevron on that side scrolls on by most of a screen. Nothing is shown on a side with nothing more.
class MoreTabs extends StatefulWidget {
  const MoreTabs({super.key, required this.child});

  /// A scrollable [TabBar].
  final Widget child;

  static const fade = 40.0;

  @override
  State<MoreTabs> createState() => _MoreTabsState();
}

class _MoreTabsState extends State<MoreTabs> {
  ScrollPosition? _position;
  bool _before = false;
  bool _after = false;

  bool _seen(Notification n) {
    final context = switch (n) {
      ScrollMetricsNotification(:final context) => context,
      ScrollNotification(:final context) => context,
      _ => null,
    };
    final metrics = switch (n) {
      ScrollMetricsNotification(:final metrics) => metrics,
      ScrollNotification(:final metrics) => metrics,
      _ => null,
    };
    if (metrics == null || metrics.axis != Axis.horizontal) return false;
    if (context != null) _position = Scrollable.maybeOf(context)?.position ?? _position;
    final before = metrics.extentBefore > 1;
    final after = metrics.extentAfter > 1;
    if (before != _before || after != _after) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _before = before;
            _after = after;
          });
        }
      });
    }
    return false;
  }

  void _go(double direction) {
    final p = _position;
    if (p == null) return;
    final to = (p.pixels + direction * p.viewportDimension * 0.7).clamp(
      p.minScrollExtent,
      p.maxScrollExtent,
    );
    if (context.still) {
      p.jumpTo(to);
    } else {
      p.animateTo(to, duration: NewsMotion.slow, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    final ground = c.bg;
    Widget chevron(bool end) => Positioned(
      top: 0,
      bottom: 0,
      left: end ? null : 0,
      right: end ? 0 : null,
      child: Pressable(
        onTap: () => _go(end ? 1 : -1),
        label: end ? s.moreTabs : s.earlierTabs,
        scale: 0.9,
        child: Container(
          width: 44,
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          padding: EdgeInsets.only(left: end ? 0 : 6, right: end ? 6 : 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: end ? Alignment.centerLeft : Alignment.centerRight,
              end: end ? Alignment.centerRight : Alignment.centerLeft,
              colors: [ground.withValues(alpha: 0), ground, ground],
              stops: const [0, 0.45, 1],
            ),
          ),
          child: NewsIcon(
            end ? NewsIcons.chevronRight : NewsIcons.chevronLeft,
            size: 20,
            color: c.textSecondary,
          ),
        ),
      ),
    );
    // Only the mask's alpha counts (dstIn): solid keeps a tab, clear lets the edge fade.
    final solid = c.textPrimary;
    return NotificationListener<Notification>(
      onNotification: _seen,
      child: Stack(
        children: [
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              final f = MoreTabs.fade / rect.width;
              return LinearGradient(
                colors: [
                  _before ? OverMedia.clear : solid,
                  solid,
                  solid,
                  _after ? OverMedia.clear : solid,
                ],
                stops: [0, f, 1 - f, 1],
              ).createShader(rect);
            },
            child: widget.child,
          ),
          if (_before) chevron(false),
          if (_after) chevron(true),
        ],
      ),
    );
  }
}
