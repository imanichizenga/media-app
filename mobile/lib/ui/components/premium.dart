import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/strings.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/premium.dart';
import '../tokens/theme.dart';

// Paid reading (ADR-0052): the marks that say a story is for subscribers.

class Crown extends StatelessWidget {
  const Crown({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: Premium.gold,
      boxShadow: Premium.glow,
    ),
    child: Center(
      child: NewsIcon(NewsIcons.crown, size: size * 0.46, color: Premium.ink, stroke: 2),
    ),
  );
}

/// On a card whose story is for subscribers: a small crown and the word, before the category.
class PremiumMark extends StatelessWidget {
  const PremiumMark({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = Premium.markInk(dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Premium.markWash(dark),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NewsIcon(NewsIcons.crown, size: 11, color: ink, stroke: 2.5),
          const SizedBox(width: 3),
          Text(
            Strings.of(context).premium.toUpperCase(),
            style: context.type.caption.copyWith(
              fontSize: 10.5,
              color: ink,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              fontVariations: const [FontVariation('wght', 700)],
            ),
          ),
        ],
      ),
    );
  }
}
