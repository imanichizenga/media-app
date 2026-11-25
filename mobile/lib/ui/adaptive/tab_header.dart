import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../components/basics.dart';
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
                      child: _name(context, t),
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
