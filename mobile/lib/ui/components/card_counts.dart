import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/account/counts.dart';
import '../../core/config/app_config.dart';
import '../../core/format/format.dart';
import '../../l10n/gen/strings.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';

/// Whether cards show counts before a story is opened (Settings → Engagement; on unless switched off).
bool cardCountsOn(WidgetRef ref) => ref.watch(flagsProvider.select((f) => f.cardCounts));

/// Views, likes and comments at the end of a card's first line, never over its picture. Only what the story
/// allows, and only once someone did it: a story nobody has liked shows no heart.
class CardCounts extends ConsumerWidget {
  const CardCounts(this.postId, {super.key, this.onMedia = false});

  final String postId;
  final bool onMedia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!cardCountsOn(ref)) return const SizedBox.shrink();
    final state = ref.watch(postStateProvider(postId)).value;
    if (state == null) return const SizedBox.shrink();
    final s = Strings.of(context);
    final c = context.colors;
    final color = onMedia ? OverMedia.soft : c.textSecondary;
    final style = context.type.caption.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final shown = [
      if (state.views > 0) (NewsIcons.eye, state.views, s.viewsCount(state.views)),
      if (state.likesOn && state.likes > 0)
        (NewsIcons.heart, state.likes, s.likesCount(state.likes)),
      if (state.commentsOn && state.comments > 0)
        (NewsIcons.messageCircle, state.comments, s.commentsCount(state.comments)),
    ];
    if (shown.isEmpty) return const SizedBox.shrink();
    return Semantics(
      label: shown.map((x) => x.$3).join(', '),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('  ·', style: style),
          for (final (icon, n, _) in shown) ...[
            const SizedBox(width: 8),
            NewsIcon(icon, size: 12, color: color, stroke: 2),
            const SizedBox(width: 3),
            Text(compact(n), style: style),
          ],
        ],
      ),
    );
  }
}
