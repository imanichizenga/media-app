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

/// Rounds at the top, as people know them from their phones (ADR-0051): live coverage first, its red ring turning
/// and marked LIVE; then the day's stories in a still red ring. Stories already read turn grey and go last, so what
/// is new is always first. The next one always peeks in and the edge fades while there is more, so the row visibly
/// goes on.
class LiveRail extends StatefulWidget {
  const LiveRail({
    super.key,
    required this.live,
    this.stories = const [],
    this.seen = const {},
    required this.onTap,
  });

  /// Null: a skeleton. Empty with no stories: nothing at all.
  final List<Story>? live;
  final List<Story> stories;

  /// Paths of the stories read on this phone.
  final Set<String> seen;
  final ValueChanged<Story> onTap;

  static const _width = 80.0;
  static const _ring = 66.0;

  /// Never more, whatever is live.
  static const extent = 124.0;

  /// The label's two lines, in the rail's own type.
  static TextStyle label(BuildContext context) =>
      context.type.caption.copyWith(color: context.colors.textPrimary, height: 1.15, fontSize: 12);

  @override
  State<LiveRail> createState() => _LiveRailState();
}

class _LiveRailState extends State<LiveRail> {
  final _scroll = ScrollController();
  var _before = false;
  var _after = true;

  void _edges(ScrollMetrics m) {
    final before = m.pixels > 1;
    final after = m.pixels < m.maxScrollExtent - 1;
    if (before != _before || after != _after) {
      setState(() {
        _before = before;
        _after = after;
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.live;
    final ids = {for (final x in live ?? const <Story>[]) x.id};
    final rest = [
      for (final x in widget.stories)
        if (!ids.contains(x.id)) x,
    ];
    if (live != null && live.isEmpty && rest.isEmpty) return const SizedBox.shrink();
    final s = Strings.of(context);
    final style = LiveRail.label(context);
    bool read(Story x) => widget.seen.contains(x.path);
    final List<(Story?, bool)> shown = live == null
        ? List.filled(5, (null, false))
        : [
            for (final x in live) (x, true),
            for (final x in rest)
              if (!read(x)) (x, false),
            for (final x in rest)
              if (read(x)) (x, false),
          ];
    const fade = 36.0;
    final solid = context.colors.textPrimary;
    return Semantics(
      container: true,
      label: s.storiesRail,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: SizedBox(
          height: LiveRail.extent,
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (n) {
              _edges(n.metrics);
              return false;
            },
            child: NotificationListener<ScrollUpdateNotification>(
              onNotification: (n) {
                _edges(n.metrics);
                return false;
              },
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                // Only the mask's alpha counts (dstIn): any opaque colour of the theme draws the row whole.
                shaderCallback: (box) => LinearGradient(
                  colors: [
                    if (_before) OverMedia.clear else solid,
                    solid,
                    solid,
                    if (_after) OverMedia.clear else solid,
                  ],
                  stops: [0, fade / box.width, 1 - fade / box.width, 1],
                ).createShader(box),
                child: ListView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(NewsSpace.s4, NewsSpace.s2, NewsSpace.s4, 0),
                  children: [
                    for (final (story, on) in shown)
                      Padding(
                        padding: const EdgeInsets.only(right: NewsSpace.s2),
                        child: Pressable(
                          onTap: story == null ? null : () => widget.onTap(story),
                          label: story == null
                              ? null
                              : [
                                  if (on) s.live,
                                  story.headline,
                                  if (read(story)) s.seenStory,
                                ].join(': '),
                          link: true,
                          scale: 0.94,
                          child: SizedBox(
                            width: LiveRail._width,
                            child: Column(
                              children: [
                                StoryRing(
                                  story: story,
                                  live: on,
                                  seen: story != null && !on && read(story),
                                  size: LiveRail._ring,
                                ),
                                const SizedBox(height: 6),
                                if (story == null)
                                  TextOrBone(null, style: style, lines: 2, align: TextAlign.center)
                                else if (on)
                                  RailLabel(story.railTitle, style: style)
                                else
                                  // A story's own headline, not a title written for the rail: two lines, then "…".
                                  Text(
                                    story.headline,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: read(story)
                                        ? style.copyWith(color: context.colors.textSecondary)
                                        : style,
                                  ),
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
        ),
      ),
    );
  }
}

/// A story's round: its picture in a ring. Live: red, turning, with a LIVE mark that breathes (still when the
/// phone asks for less motion). A story: the brand's red. Read: grey.
class StoryRing extends StatefulWidget {
  const StoryRing({
    super.key,
    required this.story,
    required this.live,
    required this.seen,
    required this.size,
  });

  final Story? story;
  final bool live;
  final bool seen;
  final double size;

  @override
  State<StoryRing> createState() => _StoryRingState();
}

class _StoryRingState extends State<StoryRing> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final move = widget.live && !context.still;
    if (move && !_turn.isAnimating) {
      _turn.repeat();
    } else if (!move) {
      _turn.stop();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    final story = widget.story;
    final picture = Container(
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
      child: ClipOval(child: NewsPicture(story?.image)),
    );
    Widget ring;
    if (story == null) {
      ring = DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.border),
        child: picture,
      );
    } else if (widget.live) {
      ring = AnimatedBuilder(
        animation: _turn,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              transform: GradientRotation(_turn.value * 6.2832),
              colors: [
                c.signalLive,
                c.signalLive.withValues(alpha: 0.25),
                c.signalLive,
                c.signalLive,
              ],
              stops: const [0, 0.35, 0.7, 1],
            ),
          ),
          child: child,
        ),
        child: picture,
      );
    } else {
      ring = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.seen ? c.borderStrong : c.brand,
        ),
        child: picture,
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SizedBox.square(dimension: widget.size, child: ring),
          if (widget.live && story != null)
            Positioned(
              bottom: 0,
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, child) => Opacity(
                  opacity: context.still ? 1 : 0.65 + 0.35 * (1 - (2 * _turn.value - 1).abs()),
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: c.signalLive,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: c.bg, width: 2),
                  ),
                  child: Text(
                    s.live.toUpperCase(),
                    style: context.type.caption.copyWith(
                      color: c.onSignalLive,
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
