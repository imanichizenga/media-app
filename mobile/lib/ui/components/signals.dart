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
        constraints: const BoxConstraints(minHeight: 48),
        color: c.signalBreakingBg,
        padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5, vertical: 4),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Row(
            children: [
              NewsIcon(NewsIcons.zap, size: 16, filled: true, color: c.signalBreakingLabel),
              const SizedBox(width: NewsSpace.s2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${s.breaking.toUpperCase()}   ',
                    style: context.type.eyebrow.copyWith(color: c.signalBreakingLabel),
                    children: [
                      TextSpan(
                        text: story.headline,
                        style: context.type.label.copyWith(
                          color: c.signalBreakingFg,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation('wght', 600)],
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: NewsSpace.s1),
              NewsIcon(NewsIcons.chevronRight, size: 18, color: c.signalBreakingFg),
            ],
          ),
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

  static const _width = 80.0;
  static const _ring = 54.0;

  /// Never more, whatever is live.
  static const extent = 96.0;

  /// The label's two lines, in the rail's own type.
  static TextStyle label(BuildContext context) =>
      context.type.caption.copyWith(color: context.colors.textPrimary, height: 1.15, fontSize: 12);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stories?.isEmpty ?? false) return const SizedBox.shrink();
    final c = context.colors;
    final s = Strings.of(context);
    final List<Story?> shown = stories ?? List.filled(4, null);
    final style = label(context);
    return Semantics(
      container: true,
      label: s.liveNow,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: SizedBox(
          height: extent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(NewsSpace.s4, NewsSpace.s1, NewsSpace.s4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final story in shown)
                  Padding(
                    padding: const EdgeInsets.only(right: NewsSpace.s1),
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
                              width: _ring,
                              height: _ring,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: story == null ? c.border : c.signalLive,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(child: NewsPicture(story?.image)),
                            ),
                            const SizedBox(height: NewsSpace.s1),
                            if (story == null)
                              TextOrBone(null, style: style, lines: 2, align: TextAlign.center)
                            else
                              RailLabel(story.railTitle, style: style),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two lines under a ring (R3): the editor's rail title, or the headline the server cut between words. A word is
/// never split; one too long for the width makes the whole label a little smaller instead.
class RailLabel extends StatelessWidget {
  const RailLabel(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  /// Smaller than this it is no longer read at a glance; the semantic label always has the whole headline.
  static const smallest = 8.5;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scaler = MediaQuery.textScalerOf(context);
      final direction = Directionality.of(context);
      bool fits(double size) {
        final sized = style.copyWith(fontSize: size);
        for (final word in text.split(' ')) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: sized),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final wide = painter.width > box.maxWidth;
          painter.dispose();
          if (wide) return false;
        }
        final painter = TextPainter(
          text: TextSpan(text: text, style: sized),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 2,
        )..layout(maxWidth: box.maxWidth);
        final fit = !painter.didExceedMaxLines;
        painter.dispose();
        return fit;
      }

      var size = style.fontSize!;
      while (size > smallest && !fits(size)) {
        size -= 0.25;
      }
      return Text(
        text,
        style: style.copyWith(fontSize: size),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    },
  );
}
