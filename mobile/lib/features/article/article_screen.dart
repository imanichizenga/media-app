import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/router.dart';
import '../../app/window.dart';
import '../../core/config/app_config.dart';
import '../../core/config/env.dart';
import '../../core/format/format.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/providers.dart';
import '../../core/telemetry/analytics.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/picture.dart';
import '../../ui/components/player.dart';
import '../../ui/components/signals.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/components/youtube.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../content/feeds.dart';
import '../content/list_screen.dart' show Initial;
import '../saved/library.dart';
import 'blocks.dart';
import 'text_size.dart';

/// One story. It opens with what its card already knew, and the rest arrives beneath.
class ArticleScreen extends ConsumerStatefulWidget {
  const ArticleScreen({
    super.key,
    required this.slug,
    required this.locale,
    required this.path,
    this.extra,
  });

  final String slug;
  final String locale;
  final String path;
  final StoryExtra? extra;

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> with WidgetsBindingObserver {
  final _scroll = ScrollController();
  final _progress = ValueNotifier<double>(0);
  final _body = GlobalKey();
  Timer? _poll;
  bool _noted = false;
  int _mark = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_measure);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _scroll.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!mounted) return;
    unawaited(ref.read(articleOfProvider(widget.slug, widget.locale).notifier).refresh());
  }

  /// How much of the text has passed the foot of the screen. What follows the text does not count.
  void _measure() {
    final box = _body.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !_scroll.hasClients) return;
    final viewport = RenderAbstractViewport.of(box);
    final end = viewport.getOffsetToReveal(box, 1).offset;
    _progress.value = end <= 0 ? 1 : (_scroll.offset / end).clamp(0.0, 1.0);
    final percent = (_progress.value * 100).round();
    for (final m in const [25, 50, 75, 100]) {
      if (percent >= m && _mark < m) {
        _mark = m;
        final story = _story;
        if (story == null) continue;
        ref.read(analyticsProvider).track(StoryRead(story.id, m));
        unawaited(ref.read(libraryProvider.notifier).readTo(story, m));
      }
    }
  }

  Story? _story;

  void _note(Story story) {
    _story = story;
    if (_noted) return;
    _noted = true;
    Future(() {
      if (!mounted) return;
      unawaited(ref.read(libraryProvider.notifier).opened(story));
      ref.read(analyticsProvider).track(StoryOpened(story.id, from: widget.extra?.from ?? 'link'));
    });
  }

  Future<void> _share(Story story) async {
    ref.read(analyticsProvider).track(StoryShared(story.id));
    await SharePlus.instance.share(
      ShareParams(uri: Uri.https(Env.webHost, story.path), subject: story.headline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = articleOfProvider(widget.slug, widget.locale);
    final state = ref.watch(provider);
    final copy = ref.watch(savedArticleProvider(widget.path)).value;
    final article = state.value?.value ?? (state.hasError ? copy : null);
    final story = article == null ? widget.extra?.story : storyOf(article);
    if (article != null) _note(story!);
    if (article != null && article.isLive && _poll == null) {
      _poll = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    }
    if (state.hasError && article == null) {
      ref.listen(movedProvider(widget.path), (_, next) {
        if (next.value case final target?) context.replace(target);
      });
      return _Failed(error: state.error!, retry: () => ref.invalidate(provider));
    }
    final c = context.colors;
    final s = Strings.of(context);
    final window = windowOf(context);
    final wide = window == WindowClass.expanded;
    final hasPicture = story == null || story.image != null;
    final moving = story != null && (story.video != null || story.youtubeId.isNotEmpty);
    final immersive = hasPicture && !moving && window == WindowClass.compact;
    final scale = ref.watch(settingsControllerProvider.select((x) => x.textScale));
    final top = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;
    final open = (Story next, {String? heroTag}) =>
        openStory(context, next, heroTag: heroTag, from: 'article');

    final reading = Column(
      key: _body,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArticleHead(article: article, story: story),
        if (!immersive && moving) ...[
          _Moving(story: story, article: article),
          const SizedBox(height: NewsSpace.s6),
        ] else if (!immersive && hasPicture) ...[
          StoryFrame(story, ratio: 3 / 2, heroTag: widget.extra?.heroTag, mark: false),
          const SizedBox(height: NewsSpace.s6),
        ],
        MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: _Scaled(MediaQuery.textScalerOf(context), scale)),
          child: ArticleBody(
            document: article == null ? null : documentOf(article),
            data: article == null
                ? null
                : BodyContext(assets: article.assets, links: article.links),
          ),
        ),
        if (article != null && article.tags.isNotEmpty) ...[
          const SizedBox(height: NewsSpace.s2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in article.tags)
                NewsChip(tag.name, onTap: () => context.push(tag.path)),
            ],
          ),
          const SizedBox(height: NewsSpace.s4),
        ],
      ],
    );

    final column = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: immersive
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.zero,
      ),
      padding: EdgeInsets.fromLTRB(
        NewsSpace.s5,
        immersive ? NewsSpace.s6 : NewsSpace.s4,
        NewsSpace.s5,
        0,
      ),
      child: wide
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: articleWidth),
                    child: reading,
                  ),
                ),
                const SizedBox(width: NewsSpace.s12),
                SizedBox(
                  width: 260,
                  child: RelatedStories(
                    slug: widget.slug,
                    locale: widget.locale,
                    open: open,
                    beside: true,
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: articleWidth),
                child: reading,
              ),
            ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.bg),
      child: Scaffold(
        body: Shimmer(
          child: Stack(
            children: [
              CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: ArticleBarDelegate(
                      top: top,
                      expanded: immersive ? math.min(width * 1.08, 520) : 0,
                      colors: c,
                      story: story,
                      heroTag: widget.extra?.heroTag,
                      progress: _progress,
                      back: s.back,
                      onBack: () =>
                          context.canPop() ? context.pop() : const HomeRoute().go(context),
                    ),
                  ),
                  SliverToBoxAdapter(child: column),
                  if (!wide)
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: articleWidth),
                          child: RelatedStories(
                            slug: widget.slug,
                            locale: widget.locale,
                            open: open,
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 132)),
                ],
              ),
              if (story != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                  child: ActionPill(
                    story: story,
                    onShare: () => _share(story),
                    onSave: !ref.watch(flagsProvider).offlineSaving
                        ? null
                        : () async {
                            final library = ref.read(libraryProvider.notifier);
                            final saved = ref.read(isSavedProvider(story.path));
                            final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
                            if (saved) {
                              await library.unsave(story);
                            } else {
                              unawaited(library.save(story, article: article));
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                margin: const EdgeInsets.fromLTRB(20, 0, 20, 92),
                                content: Text(saved ? s.removed : s.savedDone),
                                action: saved
                                    ? SnackBarAction(
                                        label: s.undo,
                                        onPressed: () => library.save(story, article: article),
                                      )
                                    : null,
                              ),
                            );
                          },
                    onText: () => showTextSize(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The reader's own size, on top of the phone's.
class _Scaled extends TextScaler {
  const _Scaled(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;
  @override
  bool operator ==(Object other) =>
      other is _Scaled && other.base == base && other.factor == factor;
  @override
  int get hashCode => Object.hash(base, factor);
}

class _Failed extends StatelessWidget {
  const _Failed({required this.error, required this.retry});

  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: RoundButton(
              NewsIcons.arrowLeft,
              label: Strings.of(context).back,
              onTap: () => context.canPop() ? context.pop() : const HomeRoute().go(context),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Designed.failure(
                  context,
                  error,
                  retry: retry,
                  home: () => const HomeRoute().go(context),
                  saved: error is OfflineFailure ? () => const SavedRoute().go(context) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The picture under the bar, the bar over the text, and how far one has read.
class ArticleBarDelegate extends SliverPersistentHeaderDelegate {
  const ArticleBarDelegate({
    required this.top,
    required this.expanded,
    required this.colors,
    required this.story,
    required this.heroTag,
    required this.progress,
    required this.back,
    required this.onBack,
  });

  final double top;
  final double expanded;
  final NewsColors colors;
  final Story? story;
  final String? heroTag;
  final ValueListenable<double> progress;
  final String back;
  final VoidCallback onBack;

  static const _lip = 28.0;

  @override
  double get minExtent => top + 56;
  @override
  double get maxExtent => math.max(minExtent, expanded);

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final c = colors;
    final room = maxExtent - minExtent;
    final t = room == 0 ? 1.0 : (shrink / room).clamp(0.0, 1.0);
    final solid = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
    final still = context.still;
    final picture = story == null
        ? const Bone.fill()
        : story!.isSensitive
        ? SensitiveCover(child: NewsPicture(story!.image))
        : NewsPicture(story!.image);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(solid > 0.5 ? c.bg : OverMedia.ground),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (room > 0)
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                maxHeight: maxExtent,
                minHeight: maxExtent,
                child: Transform.translate(
                  offset: Offset(0, still ? 0 : -shrink * 0.35),
                  child: heroTag == null ? picture : Hero(tag: heroTag!, child: picture),
                ),
              ),
            ),
          if (room > 0)
            const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fadeTop)),
              ),
            ),
          if (room > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              child: Opacity(
                opacity: 1 - solid,
                child: Container(
                  height: _lip,
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(_lip)),
                  ),
                ),
              ),
            ),
          ColoredBox(color: c.bg.withValues(alpha: solid)),
          Padding(
            padding: EdgeInsets.only(top: top, left: NewsSpace.s2, right: NewsSpace.s5),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                height: 54,
                child: Row(
                  children: [
                    RoundButton(
                      NewsIcons.arrowLeft,
                      label: back,
                      overMedia: solid < 0.5,
                      onTap: onBack,
                    ),
                    Expanded(
                      child: Opacity(
                        opacity: solid,
                        child: ExcludeSemantics(
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.2,
                            child: Text(
                              story?.headline ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.type.label.copyWith(color: c.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: ValueListenableBuilder(
              valueListenable: progress,
              builder: (context, value, _) => Opacity(
                opacity: solid,
                child: Stack(
                  children: [
                    Container(height: 2.5, color: c.border),
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 2.5,
                        color: c.mastheadRule == c.mastheadBg ? c.brand : c.mastheadRule,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(ArticleBarDelegate old) =>
      old.story != story || old.colors != colors || old.top != top || old.expanded != expanded;
}

/// Category, headline, standfirst, who and when, and what was changed since.
class ArticleHead extends ConsumerWidget {
  const ArticleHead({super.key, required this.article, required this.story});

  final Article? article;
  final Story? story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final type = context.type;
    final s = Strings.of(context);
    final now = ref.watch(clockNowProvider)();
    final a = article;
    final edited = a != null && a.modifiedAt.difference(a.publishedAt) > const Duration(minutes: 5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (story?.isLive ?? false) ...[const LivePill(), const SizedBox(width: 10)],
            Flexible(
              child: story == null
                  ? TextOrBone(null, style: type.label, last: 0.3)
                  : Pressable(
                      link: true,
                      onTap: () => context.push(story!.category.path),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            story!.category.name.toUpperCase(),
                            style: type.eyebrow.copyWith(color: c.textPrimary, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        Semantics(
          header: true,
          child: TextOrBone(
            story?.headline,
            lines: 3,
            style: type.display.copyWith(
              color: c.textPrimary,
              fontSize: 33,
              height: 1.14,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: NewsSpace.s3),
        if (story == null || story!.standfirst.isNotEmpty)
          TextOrBone(
            story?.standfirst,
            lines: 2,
            style: type.serif.copyWith(color: c.textSecondary, fontSize: 20),
          ),
        const SizedBox(height: NewsSpace.s5),
        _Byline(article: a, story: story),
        if (a != null && a.updateNote.isNotEmpty)
          _Note(
            title: s.updateNote,
            text: a.updateNote,
            ink: c.textPrimary,
            ground: c.surfaceSunken,
          ),
        if (a != null && a.correctionNote.isNotEmpty)
          _Note(title: s.correction, text: a.correctionNote, ink: c.warning, ground: c.warningSoft),
        if (a != null && a.contentWarning.isNotEmpty)
          _Note(
            title: s.sensitive,
            text: a.contentWarning,
            ink: c.textPrimary,
            ground: c.surfaceSunken,
          ),
        if (edited) ...[
          const SizedBox(height: NewsSpace.s3),
          Text(
            s.updated(ago(a.modifiedAt, s, now)),
            style: type.caption.copyWith(color: c.textSecondary),
          ),
        ],
        if (a != null && a.liveEndedAt != null) ...[
          const SizedBox(height: NewsSpace.s3),
          Text(s.liveEnded, style: type.label.copyWith(color: c.textSecondary)),
        ],
        const SizedBox(height: NewsSpace.s6),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.title, required this.text, required this.ink, required this.ground});

  final String title;
  final String text;
  final Color ink;
  final Color ground;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: NewsSpace.s4),
    padding: const EdgeInsets.all(NewsSpace.s4),
    decoration: BoxDecoration(color: ground, borderRadius: BorderRadius.circular(NewsRadius.md)),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title. ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontVariations: [FontVariation('wght', 600)],
            ),
          ),
          TextSpan(text: text),
        ],
      ),
      style: context.type.bodyM.copyWith(color: ink),
    ),
  );
}

class _Byline extends ConsumerWidget {
  const _Byline({required this.article, required this.story});

  final Article? article;
  final Story? story;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final type = context.type;
    final s = Strings.of(context);
    final author = article?.authors.firstOrNull;
    if (article != null && author == null) return const SizedBox.shrink();
    final who = article == null ? null : article!.authors.map((a) => a.name).join(', ');
    final line = story == null
        ? null
        : [
            ago(story!.publishedAt, s, ref.watch(clockNowProvider)()),
            s.minutesRead(story!.readingMinutes < 1 ? 1 : story!.readingMinutes),
          ].join('  ·  ');
    final row = Row(
      children: [
        SizedBox.square(
          dimension: 46,
          child: ClipOval(
            child: author != null && author.avatar == null
                ? Initial(author.name, size: 46)
                : NewsPicture(author?.avatar),
          ),
        ),
        const SizedBox(width: NewsSpace.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: TextOrBone(
                      who ?? (story?.byline.isEmpty ?? true ? null : story!.byline),
                      last: 0.5,
                      style: type.title.copyWith(color: c.textPrimary, fontSize: 15),
                    ),
                  ),
                  if (who != null) ...[
                    const SizedBox(width: 5),
                    Semantics(
                      label: s.verified,
                      child: NewsIcon(NewsIcons.badgeCheck, size: 16, color: c.textSecondary),
                    ),
                  ],
                ],
              ),
              TextOrBone(line, last: 0.7, style: type.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.border)),
      ),
      child: author == null
          ? row
          : Pressable(link: true, onTap: () => context.push(author.path), child: row),
    );
  }
}

/// The story is a video: it stands where the picture would.
class _Moving extends ConsumerWidget {
  const _Moving({required this.story, required this.article});

  final Story story;
  final Article? article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = story.video;
    if (video != null) {
      return NewsPlayer(
        hls: video.hls,
        poster: video.poster,
        color: video.color,
        label: story.headline,
        ratio: ratioOf(video),
        length: story.length,
        onProgress: (p) => ref.read(analyticsProvider).track(VideoPlayed(story.id, p)),
      );
    }
    return YoutubeFacade(
      videoId: story.youtubeId,
      title: story.headline,
      image: story.image,
      enabled: ref.watch(flagsProvider).youtube,
    );
  }
}

/// What one can do with the story, within reach of the thumb. More arrives with accounts (M4).
class ActionPill extends ConsumerWidget {
  const ActionPill({
    super.key,
    required this.story,
    required this.onShare,
    required this.onSave,
    required this.onText,
  });

  final Story story;
  final VoidCallback onShare;
  final VoidCallback? onSave;
  final VoidCallback onText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = Strings.of(context);
    final saved = ref.watch(isSavedProvider(story.path));
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: c.border),
          boxShadow: OverMedia.shadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundButton(NewsIcons.aLargeSmall, label: s.textSize, onTap: onText),
            if (onSave != null)
              RoundButton(
                NewsIcons.bookmark,
                label: saved ? s.unsave : s.save,
                filled: saved,
                haptic: true,
                onTap: onSave,
              ),
            const SizedBox(width: 4),
            Pressable(
              onTap: onShare,
              haptic: true,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: c.brand, borderRadius: BorderRadius.circular(26)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NewsIcon(NewsIcons.share2, size: 18, color: c.onBrand),
                    const SizedBox(width: 8),
                    Text(s.share, style: context.type.label.copyWith(color: c.onBrand)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What to read after this: the next story large, the others beneath.
class RelatedStories extends ConsumerWidget {
  const RelatedStories({
    super.key,
    required this.slug,
    required this.locale,
    required this.open,
    this.beside = false,
  });

  final String slug;
  final String locale;
  final OpenStory open;
  final bool beside;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final found = ref.watch(relatedProvider(slug, locale));
    if (found.hasError || (found.value?.isEmpty ?? false)) return const SizedBox.shrink();
    final s = Strings.of(context);
    final List<Story?> stories = found.value ?? List.filled(4, null);
    if (found.value case [final next, ...]) {
      // Ready before it is asked for.
      ref.watch(articleOfProvider(next.slug, next.locale));
    }
    if (beside) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHead(s.readAlso, padded: false),
          for (final story in stories.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: NewsSpace.s6),
              child: StandardCard(story, open: open, place: 'beside', large: false),
            ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: NewsSpace.s6),
        SectionHead(s.nextStory),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
          child: CoverCard(stories.first, open: open, place: 'next', radius: NewsRadius.xl),
        ),
        if (stories.length > 1) ...[
          const SizedBox(height: NewsSpace.s8),
          SectionHead(s.readAlso),
          for (final (i, story) in stories.skip(1).take(4).indexed) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: NewsSpace.s5),
                child: Divider(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
              child: RowCard(story, open: open, place: 'related'),
            ),
          ],
        ],
      ],
    );
  }
}
