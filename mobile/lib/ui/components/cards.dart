import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/format/format.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';
import 'basics.dart';
import 'picture.dart';
import 'signals.dart';
import 'skeleton.dart';
import 'story_menu.dart';

/// Every card: picture, then *category · time*, then headline. A null story draws the same card in bones.
typedef OpenStory = void Function(Story story, {String? heroTag});

/// What a card is about and how fresh it is: always the first line, always in this order.
class Kicker extends ConsumerWidget {
  const Kicker(
    this.story, {
    super.key,
    this.onMedia = false,
    this.quiet = false,
    this.reading = false,
  });

  final Story? story;
  final bool onMedia;

  /// The picture already carries the LIVE pill.
  final bool quiet;

  /// Also how long it takes to read.
  final bool reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final strong = context.type.caption.copyWith(
      color: onMedia ? OverMedia.ink : c.textPrimary,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 600)],
    );
    final story = this.story;
    if (story == null) return TextOrBone(null, style: strong, last: 0.35);
    final s = Strings.of(context);
    final now = ref.watch(clockNowProvider)();
    final soft = context.type.caption.copyWith(color: onMedia ? OverMedia.soft : c.textSecondary);
    final when = [
      ago(story.publishedAt, s, now),
      if (reading) s.minutesRead(story.readingMinutes < 1 ? 1 : story.readingMinutes),
    ].join('  ·  ');
    final live = story.isLive && !quiet;
    return MetaLine(
      lead: live
          ? const LivePill()
          : Text.rich(
              TextSpan(
                text: story.isBreaking(now) ? s.breaking : story.category.name,
                style: strong,
                children: [TextSpan(text: '  ·', style: soft)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
      // The time is said whole; what it belongs to gives way.
      rest: Text(when, style: soft, maxLines: 1, softWrap: false),
    );
  }
}

/// One line, always. What leads gives way to what follows, which shrinks only when it alone is too long.
class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.lead, required this.rest});

  final Widget lead;
  final Widget rest;

  static const _gap = 7.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(right: _gap),
            child: lead,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: box.maxWidth),
          child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: rest),
        ),
      ],
    ),
  );
}

/// In a corner of the picture: how long a video is, how many pictures there are.
class _Mark extends StatelessWidget {
  const _Mark(this.story);

  final Story story;

  @override
  Widget build(BuildContext context) {
    if (story.isLive) return const LivePill();
    final (icon, text) = switch (story) {
      _ when story.isVideo && story.length != null => (NewsIcons.play, clock(story.length!)),
      Story(type: Kind.gallery) => (NewsIcons.images, Strings.of(context).gallery),
      _ => (null, ''),
    };
    if (icon == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OverMedia.chip,
        borderRadius: BorderRadius.circular(NewsRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NewsIcon(icon, size: 12, color: OverMedia.ink, filled: icon == NewsIcons.play),
          const SizedBox(width: 5),
          Text(
            text,
            style: context.type.caption.copyWith(
              color: OverMedia.ink,
              fontSize: 12,
              height: 1.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// The picture of a card in its fixed shape.
class StoryFrame extends StatelessWidget {
  const StoryFrame(
    this.story, {
    super.key,
    required this.ratio,
    this.radius = NewsRadius.lg,
    this.mark = true,
    this.heroTag,
  });

  final Story? story;
  final double ratio;
  final double radius;
  final bool mark;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final story = this.story;
    Widget picture = story != null && story.image == null
        ? ColoredBox(color: context.colors.surfaceSunken, child: const SizedBox.expand())
        : NewsPicture(story?.image);
    if (story?.isSensitive ?? false) {
      picture = SensitiveCover(child: picture);
    }
    if (heroTag != null && story != null) {
      picture = Hero(tag: heroTag!, child: picture);
    }
    return AspectRatio(
      aspectRatio: ratio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            picture,
            if (story != null && mark) Positioned(left: 10, bottom: 10, child: _Mark(story)),
          ],
        ),
      ),
    );
  }
}

/// Blurred until asked. On cards it only warns; the article lets the reader decide.
class SensitiveCover extends StatelessWidget {
  const SensitiveCover({super.key, required this.child, this.onShow});

  final Widget child;
  final VoidCallback? onShow;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: ImageFiltered(
            imageFilter: const ColorFilter.mode(OverMedia.scrim, BlendMode.srcOver),
            child: ImageFiltered(imageFilter: blurHeavy, child: child),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NewsIcon(NewsIcons.eyeOff, size: 22, color: OverMedia.ink),
                if (onShow != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    s.sensitive,
                    textAlign: TextAlign.center,
                    style: context.type.label.copyWith(color: OverMedia.ink),
                  ),
                  const SizedBox(height: 12),
                  NewsButton(s.sensitiveShow, onTap: onShow, kind: ButtonKind.secondary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _say(BuildContext context, Story story, DateTime now) {
  final s = Strings.of(context);
  return [
    if (story.isLive) s.live else story.category.name,
    story.headline,
    if (story.length != null && story.isVideo) clock(story.length!),
    if (story.isSensitive) s.sensitive,
    ago(story.publishedAt, s, now),
  ].join('. ');
}

class _Tap extends ConsumerWidget {
  const _Tap({required this.story, required this.open, required this.child, this.heroTag});

  final Story? story;
  final OpenStory open;
  final Widget child;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = this.story;
    if (story == null) return child;
    final menu = StoryMenu.of(context);
    return Pressable(
      link: true,
      label: _say(context, story, ref.watch(clockNowProvider)()),
      onTap: () => open(story, heroTag: heroTag),
      onHold: menu == null ? null : () => menu.open(context, story, StoryPreview(story)),
      child: child,
    );
  }
}

/// What a held card shows of itself: nothing in it can be pressed or fly.
class StoryPreview extends StatelessWidget {
  const StoryPreview(this.story, {super.key});

  final Story story;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (story.image != null) ...[
        StoryFrame(story, ratio: 16 / 9, radius: NewsRadius.md),
        const SizedBox(height: NewsSpace.s3),
      ],
      Kicker(story, quiet: true),
      const SizedBox(height: NewsSpace.s1),
      Text(
        story.headline,
        style: context.type.headlineS.copyWith(color: context.colors.textPrimary, height: 1.24),
      ),
    ],
  );
}

/// The lead's picture: as tall as leaves room for what follows (S1).
double leadRatio(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 600 || size.height < 720 ? 16 / 9 : 4 / 3;
}

/// The one story of the screen: the picture fills it, the headline sits on the picture.
class CoverCard extends StatelessWidget {
  const CoverCard(
    this.story, {
    super.key,
    required this.open,
    this.place = 'cover',
    this.radius = 0,
    this.ratio,
  });

  final Story? story;
  final OpenStory open;
  final String place;
  final double radius;
  final double? ratio;

  @override
  Widget build(BuildContext context) {
    final story = this.story;
    final tag = story == null ? null : '$place-${story.id}';
    final type = context.type;
    final shape = ratio ?? leadRatio(context);
    return _Tap(
      story: story,
      open: open,
      heroTag: tag,
      child: LayoutBuilder(
        builder: (context, box) => ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Positioned.fill(
                child: story == null
                    ? const Bone.fill()
                    : Hero(
                        tag: tag!,
                        child: story.isSensitive
                            ? SensitiveCover(child: NewsPicture(story.image))
                            : NewsPicture(story.image),
                      ),
              ),
              if (story != null)
                const Positioned.fill(
                  child: DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: box.maxWidth / shape,
                  minWidth: box.maxWidth,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  heightFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NewsSpace.s5,
                      NewsSpace.s8,
                      NewsSpace.s5,
                      NewsSpace.s4,
                    ),
                    child: story == null
                        ? const _CoverBones()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Kicker(story, onMedia: true, reading: true),
                              const SizedBox(height: NewsSpace.s1),
                              Text(
                                story.headline,
                                style:
                                    (box.maxWidth >= 560
                                            ? type.headlineL.copyWith(height: 1.14)
                                            : type.headlineM.copyWith(height: 1.18))
                                        .copyWith(
                                          color: OverMedia.ink,
                                          shadows: OverMedia.textShadow,
                                        ),
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
    );
  }
}

class _CoverBones extends StatelessWidget {
  const _CoverBones();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.bg.withValues(alpha: 0.55);
    Widget bar(double part, double height) => FractionallySizedBox(
      widthFactor: part,
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(0.4, 12), bar(0.92, 22), bar(0.7, 22)],
    );
  }
}

/// Wide picture above, for the story that earns it.
class StandardCard extends StatelessWidget {
  const StandardCard(
    this.story, {
    super.key,
    required this.open,
    this.place = 'card',
    this.ratio = 16 / 10,
    this.large = true,
  });

  final Story? story;
  final OpenStory open;
  final String place;
  final double ratio;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final tag = story == null ? null : '$place-${story!.id}';
    final type = context.type;
    return _Tap(
      story: story,
      open: open,
      heroTag: tag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoryFrame(story, ratio: ratio, heroTag: tag),
          const SizedBox(height: NewsSpace.s3),
          Kicker(story, quiet: true),
          const SizedBox(height: NewsSpace.s1),
          TextOrBone(
            story?.headline,
            lines: 2,
            style: (large ? type.headlineM : type.headlineS).copyWith(
              color: context.colors.textPrimary,
              height: 1.22,
            ),
          ),
        ],
      ),
    );
  }
}

/// Picture beside, the everyday card.
class RowCard extends StatelessWidget {
  const RowCard(this.story, {super.key, required this.open, this.place = 'row', this.trailing});

  final Story? story;
  final OpenStory open;
  final String place;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tag = story == null ? null : '$place-${story!.id}';
    final picture = story == null || story!.image != null;
    return _Tap(
      story: story,
      open: open,
      heroTag: picture ? tag : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NewsSpace.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kicker(story),
                  const SizedBox(height: 6),
                  TextOrBone(
                    story?.headline,
                    lines: 2,
                    maxLines: 4,
                    style: context.type.headlineS.copyWith(
                      color: context.colors.textPrimary,
                      fontSize: 19,
                      height: 1.24,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            if (picture) ...[
              const SizedBox(width: NewsSpace.s4),
              SizedBox(
                width: 108,
                child: StoryFrame(
                  story,
                  ratio: 1,
                  radius: NewsRadius.md,
                  mark: story?.isVideo ?? false,
                  heroTag: tag,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Words only, for the river.
class CompactCard extends StatelessWidget {
  const CompactCard(this.story, {super.key, required this.open});

  final Story? story;
  final OpenStory open;

  @override
  Widget build(BuildContext context) => _Tap(
    story: story,
    open: open,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Kicker(story),
          const SizedBox(height: 4),
          TextOrBone(
            story?.headline,
            lines: 2,
            style: context.type.headlineS.copyWith(
              color: context.colors.textPrimary,
              fontSize: 17,
              height: 1.28,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Someone's view: their words lead, and the quotation mark says so.
class OpinionCard extends StatelessWidget {
  const OpinionCard(this.story, {super.key, required this.open});

  final Story? story;
  final OpenStory open;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Tap(
      story: story,
      open: open,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
        padding: const EdgeInsets.all(NewsSpace.s5),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(NewsRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NewsIcon(NewsIcons.quote, size: 24, color: c.textTertiary),
            const SizedBox(height: NewsSpace.s3),
            TextOrBone(
              story?.headline,
              lines: 2,
              style: context.type.headlineM.copyWith(
                color: c.textPrimary,
                height: 1.25,
                fontWeight: FontWeight.w500,
                fontVariations: const [FontVariation('wght', 500)],
              ),
            ),
            const SizedBox(height: NewsSpace.s3),
            TextOrBone(
              story == null ? null : [Strings.of(context).opinion, story!.byline].join('  ·  '),
              last: 0.5,
              style: context.type.label.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Several pictures are the point: one large, two beside it in its own colour.
class GalleryCard extends StatelessWidget {
  const GalleryCard(this.story, {super.key, required this.open});

  final Story? story;
  final OpenStory open;

  @override
  Widget build(BuildContext context) =>
      StandardCard(story, open: open, place: 'gallery', ratio: 4 / 3);
}

/// Coverage that goes on: the pill, the headline, and what it is.
class LiveBlogCard extends StatelessWidget {
  const LiveBlogCard(this.story, {super.key, required this.open});

  final Story? story;
  final OpenStory open;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tag = story == null ? null : 'live-${story!.id}';
    return _Tap(
      story: story,
      open: open,
      heroTag: tag,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(NewsRadius.lg + 1),
          color: c.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StoryFrame(story, ratio: 2, radius: 0, mark: false, heroTag: tag),
            Padding(
              padding: const EdgeInsets.all(NewsSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Kicker(story),
                  const SizedBox(height: NewsSpace.s2),
                  TextOrBone(
                    story?.headline,
                    lines: 2,
                    style: context.type.headlineM.copyWith(color: c.textPrimary, height: 1.2),
                  ),
                  const SizedBox(height: NewsSpace.s2),
                  TextOrBone(
                    story == null ? null : Strings.of(context).liveBlog,
                    last: 0.5,
                    style: context.type.label.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Says that a picture plays: on the lead video only, the others say how long they are (V1).
class PlayDisc extends StatelessWidget {
  const PlayDisc({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: OverMedia.chip, shape: BoxShape.circle),
    child: const Padding(
      padding: EdgeInsets.only(left: 3),
      child: NewsIcon(NewsIcons.play, size: 24, filled: true, color: OverMedia.ink),
    ),
  );
}

class VideoCard extends StatelessWidget {
  const VideoCard(
    this.story, {
    super.key,
    required this.open,
    this.place = 'video',
    this.large = false,
    this.lead = false,
  });

  final Story? story;
  final OpenStory open;
  final String place;
  final bool large;
  final bool lead;

  @override
  Widget build(BuildContext context) {
    final tag = story == null ? null : '$place-${story!.id}';
    final type = context.type;
    return _Tap(
      story: story,
      open: open,
      heroTag: tag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              StoryFrame(story, ratio: 16 / 9, heroTag: tag),
              if (lead && story != null && !story!.isSensitive) const PlayDisc(),
            ],
          ),
          const SizedBox(height: NewsSpace.s3),
          Kicker(story, quiet: true),
          const SizedBox(height: NewsSpace.s1),
          TextOrBone(
            story?.headline,
            lines: 2,
            maxLines: large ? null : 3,
            style: (large ? type.headlineM : type.headlineS).copyWith(
              color: context.colors.textPrimary,
              fontSize: large ? null : 17,
              height: 1.24,
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical video, the headline on the picture.
class ShortCard extends StatelessWidget {
  const ShortCard(this.story, {super.key, required this.onTap});

  final Story? story;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AspectRatio(
      aspectRatio: 9 / 15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NewsRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ShortPoster(story),
            if (story != null) ...[
              const DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story!.headline,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.label.copyWith(
                        color: OverMedia.ink,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                    if (story!.length != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        clock(story!.length!),
                        style: context.type.caption.copyWith(color: OverMedia.soft, height: 1.2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return story == null
        ? card
        : Pressable(onTap: onTap, link: true, label: story!.headline, scale: 0.96, child: card);
  }
}

/// The still of a vertical video, before it moves.
class ShortPoster extends ConsumerWidget {
  const ShortPoster(this.story, {super.key});

  final Story? story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = story?.video;
    if (story == null) return const Bone.fill();
    if (video == null || video.poster.isEmpty) return NewsPicture(story!.image);
    return PosterPicture(poster: video.poster, color: video.color);
  }
}

/// How any kind of story looks in a mixed list.
class FeedCard extends StatelessWidget {
  const FeedCard(
    this.story, {
    super.key,
    required this.open,
    this.place = 'feed',
    this.feature = false,
  });

  final Story? story;
  final OpenStory open;
  final String place;

  /// Every few stories one is given room.
  final bool feature;

  @override
  Widget build(BuildContext context) {
    final story = this.story;
    Widget roomy(Widget card) => Padding(
      padding: const EdgeInsets.symmetric(vertical: NewsSpace.s4),
      child: card,
    );
    return switch (story?.type) {
      Kind.liveBlog || Kind.liveStream when story!.isLive => LiveBlogCard(story, open: open),
      Kind.video || Kind.youtube => roomy(VideoCard(story, open: open, place: place, large: true)),
      Kind.gallery => roomy(GalleryCard(story, open: open)),
      Kind.opinion => OpinionCard(story, open: open),
      _ when story != null && story.image == null => CompactCard(story, open: open),
      _ when feature && story != null => roomy(StandardCard(story, open: open, place: place)),
      _ => RowCard(story, open: open, place: place),
    };
  }
}
