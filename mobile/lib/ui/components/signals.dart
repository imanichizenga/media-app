import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/models.dart';
import '../../l10n/gen/strings.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';
import 'basics.dart';
import 'picture.dart';
import 'skeleton.dart';

/// LIVE is this shape and nothing else is: a filled pill with a dot, the only thing that moves by itself.
class LivePill extends StatelessWidget {
  const LivePill({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.signalLive, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: c.onSignalLive),
          const SizedBox(width: 6),
          Text(
            Strings.of(context).live.toUpperCase(),
            style: context.type.eyebrow.copyWith(color: c.onSignalLive, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.35,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.still) {
      _pulse.value = 1;
    } else {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _pulse,
    child: Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

/// BREAKING is this shape and nothing else is: full width, an icon, capitals. Absent when nothing is.
class BreakingBanner extends StatelessWidget {
  const BreakingBanner({super.key, required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    return Pressable(
      onTap: onTap,
      link: true,
      label: '${s.breaking}: ${story.headline}',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.signalBreakingBg,
          border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(NewsSpace.s5, 14, NewsSpace.s4, 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.signalBreakingLabel.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: NewsIcon(NewsIcons.zap, size: 17, filled: true, color: c.signalBreakingLabel),
            ),
            const SizedBox(width: NewsSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.breaking.toUpperCase(),
                    style: context.type.eyebrow.copyWith(color: c.signalBreakingLabel, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    story.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.title.copyWith(
                      color: c.signalBreakingFg,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: NewsSpace.s2),
            NewsIcon(NewsIcons.chevronRight, size: 18, color: c.signalBreakingFg),
          ],
        ),
      ),
    );
  }
}

/// Circles with a ring, a shape nothing else has. The next one always peeks in, so the row visibly scrolls.
class LiveRail extends ConsumerWidget {
  const LiveRail({super.key, required this.stories, required this.onTap});

  /// Null: a skeleton. Empty: nothing at all.
  final List<Story>? stories;
  final ValueChanged<Story> onTap;

  static const _width = 92.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stories?.isEmpty ?? false) return const SizedBox.shrink();
    final c = context.colors;
    final s = Strings.of(context);
    final List<Story?> shown = stories ?? List.filled(4, null);
    final style = context.type.caption.copyWith(color: c.textPrimary, height: 1.25, fontSize: 12.5);
    return Semantics(
      container: true,
      label: s.liveNow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(NewsSpace.s4, NewsSpace.s4, NewsSpace.s4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final story in shown)
              Padding(
                padding: const EdgeInsets.only(right: NewsSpace.s3),
                child: Pressable(
                  onTap: story == null ? null : () => onTap(story),
                  label: story == null ? null : '${s.live}: ${story.headline}',
                  link: true,
                  scale: 0.95,
                  child: SizedBox(
                    width: _width,
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: story == null ? c.border : c.signalLive,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(child: NewsPicture(story?.image)),
                        ),
                        const SizedBox(height: NewsSpace.s2),
                        TextOrBone(
                          story?.headline,
                          style: style,
                          lines: 2,
                          maxLines: 2,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
