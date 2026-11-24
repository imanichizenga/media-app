import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/format/format.dart';
import '../../core/providers.dart';
import '../../ui/components/basics.dart';
import '../../ui/tokens/theme.dart';

/// Large with the date at rest; the name alone once the reader is under way.
class HomeMasthead extends ConsumerWidget {
  const HomeMasthead({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SliverPersistentHeader(
    pinned: true,
    delegate: _Delegate(
      top: MediaQuery.paddingOf(context).top,
      date: longDate(ref.watch(clockNowProvider)(), ref.watch(localeNameProvider)),
      colors: context.colors,
    ),
  );
}

class _Delegate extends SliverPersistentHeaderDelegate {
  const _Delegate({required this.top, required this.date, required this.colors});

  final double top;
  final String date;
  final NewsColors colors;

  @override
  double get minExtent => top + 52;
  @override
  double get maxExtent => top + 92;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final t = (shrink / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final c = colors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.mastheadBg),
      child: Container(
        decoration: BoxDecoration(
          color: c.mastheadBg,
          border: Border(bottom: BorderSide(color: c.mastheadRule, width: 2)),
        ),
        padding: EdgeInsets.only(top: top, left: NewsSpace.s5, right: NewsSpace.s5),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 14 - 8 * t,
                child: Opacity(
                  opacity: (1 - t * 2).clamp(0, 1),
                  child: Text(
                    date,
                    style: context.type.eyebrow.copyWith(color: c.navFg, height: 1.2),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(-1, 1 - t),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 10 * (1 - t)),
                  child: Semantics(header: true, child: Wordmark(size: 34 - 11 * t)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_Delegate old) =>
      old.top != top || old.date != date || old.colors != colors;
}
