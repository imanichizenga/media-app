import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../app/router.dart';
import '../../core/config/app_config.dart';
import '../../core/config/env.dart';
import '../../core/format/format.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../core/network/images.dart';
import '../../core/providers.dart';
import '../../core/telemetry/analytics.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../content/feeds.dart';
import '../saved/library.dart';
import 'shorts_pool.dart';
import 'video_screen.dart';

part 'shorts.g.dart';

/// Replaced in tests.
@Riverpod(keepAlive: true)
MakeController makeController(Ref ref) => networkController;

/// One vertical video after another. Always dark, in every theme.
class Shorts extends ConsumerStatefulWidget {
  const Shorts({super.key, this.header});

  final Widget? header;

  @override
  ConsumerState<Shorts> createState() => _ShortsState();
}

class _ShortsState extends ConsumerState<Shorts> with WidgetsBindingObserver {
  final _pages = PageController();
  late final ShortsPool _pool;
  List<Story> _stories = const [];
  bool _started = false;
  bool _foreground = true;

  FeedKey get _key => FeedKey(FeedKind.type, 'short', ref.read(localeNameProvider));

  @override
  void initState() {
    super.initState();
    final pictures = ref.read(picturesProvider.notifier);
    _pool = ShortsPool(
      urls: () => [for (final s in _stories) pictures.address(s.video?.hls ?? '')],
      make: ref.read(makeControllerProvider),
      autoplay: ref.read(autoplayProvider),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pool.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _pool.awake(_foreground && TickerMode.valuesOf(context).enabled);
  }

  void _shown(int i) {
    if (i < _stories.length) {
      unawaited(_pool.show(i));
      ref.read(analyticsProvider).track(VideoPlayed(_stories[i].id, 0));
    }
    if (i >= _stories.length - 4) {
      unawaited(ref.read(feedProvider(_key).notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedProvider(_key));
    final s = Strings.of(context);
    // Another tab, or a story over this one: nothing plays unseen.
    _pool.awake(
      _foreground &&
          TickerMode.valuesOf(context).enabled &&
          (ModalRoute.of(context)?.isCurrent ?? true),
    );
    _stories = [
      for (final x in state.value?.stories ?? const <Story>[])
        if (x.video != null) x,
    ];
    if (!_started && _stories.isNotEmpty) {
      _started = true;
      final id = ref.read(startShortProvider);
      final at = id == null ? 0 : _stories.indexWhere((x) => x.id == id).clamp(0, _stories.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (at > 0) _pages.jumpToPage(at);
        ref.read(startShortProvider.notifier).done();
        _shown(at);
      });
    }
    ref.listen(startShortProvider, (_, id) {
      if (id == null || !_pages.hasClients) return;
      final at = _stories.indexWhere((x) => x.id == id);
      if (at >= 0) _pages.jumpToPage(at);
      Future(ref.read(startShortProvider.notifier).done);
    });
    final top = MediaQuery.paddingOf(context).top;
    Widget body;
    if (state case AsyncError(:final error) when state.value == null) {
      body = Theme(
        data: Theme.of(context).copyWith(
          extensions: [ref.read(themeChoiceProvider).colors(ThemeScheme.dark), const AppType()],
        ),
        child: Builder(
          builder: (context) => Center(
            child: SingleChildScrollView(
              child: Designed.failure(
                context,
                error,
                retry: () => ref.invalidate(feedProvider(_key)),
                saved: error is OfflineFailure ? () => const SavedRoute().go(context) : null,
              ),
            ),
          ),
        ),
      );
    } else if (state.value == null) {
      body = const ShortSkeleton();
    } else {
      body = PageView.builder(
        controller: _pages,
        scrollDirection: Axis.vertical,
        onPageChanged: (i) {
          HapticFeedback.selectionClick();
          _shown(i);
        },
        itemCount: _stories.length + (state.value!.next == null ? 1 : 0),
        itemBuilder: (context, i) => i == _stories.length
            ? _End(
                again: () {
                  _pages.jumpToPage(0);
                },
              )
            : ShortPage(story: _stories[i], index: i, pool: _pool),
      );
    }
    return Scaffold(
      backgroundColor: OverMedia.ground,
      body: Center(
        // On a tablet the picture keeps its shape, on a phone it fills the screen.
        child: _Window(
          child: Stack(
            fit: StackFit.expand,
            children: [
              body,
              // Whatever is filmed, what stands on it can be read.
              const Align(
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fadeTop)),
                  ),
                ),
              ),
              if (widget.header != null)
                Positioned(
                  top: top + 8,
                  left: 0,
                  right: 0,
                  child: Center(child: widget.header),
                ),
              if (_stories.isNotEmpty)
                Positioned(
                  top: top + 8,
                  right: 8,
                  child: ListenableBuilder(
                    listenable: _pool,
                    builder: (context, _) => RoundButton(
                      _pool.muted ? NewsIcons.volumeX : NewsIcons.volume2,
                      label: _pool.muted ? s.unmute : s.mute,
                      overMedia: true,
                      haptic: true,
                      onTap: _pool.toggleMute,
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

class ShortPage extends ConsumerWidget {
  const ShortPage({super.key, required this.story, required this.index, required this.pool});

  final Story story;
  final int index;
  final ShortsPool pool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final saved = ref.watch(isSavedProvider(story.path));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ListenableBuilder(
        listenable: pool,
        builder: (context, _) {
          final controller = pool.at(index);
          return Stack(
            fit: StackFit.expand,
            children: [
              ShortPoster(story),
              if (controller != null)
                RepaintBoundary(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
              const IgnorePointer(
                child: DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.short)),
              ),
              Semantics(
                button: true,
                label: pool.held ? s.play : s.pause,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: pool.failed(index) ? pool.retry : pool.toggleHold,
                ),
              ),
              if (pool.held || pool.failed(index))
                IgnorePointer(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BigPlayGlyph(),
                      if (pool.failed(index)) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${s.videoError}. ${s.retry}',
                          style: context.type.label.copyWith(color: OverMedia.ink),
                        ),
                      ],
                    ],
                  ),
                ),
              Positioned(
                left: 20,
                right: 12,
                bottom: 22,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Kicker(story, onMedia: true),
                          const SizedBox(height: 6),
                          Text(
                            story.headline,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: context.type.headlineM.copyWith(
                              color: OverMedia.ink,
                              height: 1.2,
                              shadows: OverMedia.textShadow,
                            ),
                          ),
                          if (story.byline.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              story.byline,
                              style: context.type.label.copyWith(color: OverMedia.soft),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Pressable(
                            link: true,
                            onTap: () =>
                                context.push(story.path, extra: StoryExtra(story, from: 'shorts')),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              decoration: BoxDecoration(
                                color: OverMedia.chip,
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: OverMedia.faint),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      s.watchFull,
                                      style: context.type.label.copyWith(color: OverMedia.ink),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const NewsIcon(
                                    NewsIcons.arrowRight,
                                    size: 16,
                                    color: OverMedia.ink,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (ref.watch(flagsProvider).offlineSaving)
                          _Act(
                            icon: NewsIcons.bookmark,
                            text: s.save,
                            label: saved ? s.unsave : s.save,
                            filled: saved,
                            onTap: () {
                              final library = ref.read(libraryProvider.notifier);
                              unawaited(saved ? library.unsave(story) : library.save(story));
                            },
                          ),
                        _Act(
                          icon: NewsIcons.share2,
                          text: s.share,
                          label: s.share,
                          onTap: () {
                            ref.read(analyticsProvider).track(StoryShared(story.id));
                            unawaited(
                              SharePlus.instance.share(
                                ShareParams(
                                  uri: Uri.https(Env.webHost, story.path),
                                  subject: story.headline,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: controller == null
                    ? const SizedBox(height: 3)
                    : _Progress(controller: controller),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BigPlayGlyph extends StatelessWidget {
  const BigPlayGlyph({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: OverMedia.chip, shape: BoxShape.circle),
    child: const Padding(
      padding: EdgeInsets.only(left: 5),
      child: NewsIcon(NewsIcons.play, size: 34, filled: true, color: OverMedia.ink),
    ),
  );
}

class _Act extends StatelessWidget {
  const _Act({
    required this.icon,
    required this.text,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final NewsIconData icon;
  final String text;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    haptic: true,
    scale: 0.9,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: OverMedia.chip, shape: BoxShape.circle),
            child: NewsIcon(icon, size: 23, color: OverMedia.ink, filled: filled),
          ),
          const SizedBox(height: 4),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Text(
              text,
              style: context.type.caption.copyWith(
                color: OverMedia.ink,
                fontSize: 12,
                shadows: OverMedia.textShadow,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: controller,
    builder: (context, v, _) {
      final total = v.duration.inMilliseconds;
      return Semantics(
        label: Strings.of(context).position(clock(v.position), clock(v.duration)),
        child: Stack(
          children: [
            Container(height: 3, color: OverMedia.faint),
            FractionallySizedBox(
              widthFactor: total == 0 ? 0 : (v.position.inMilliseconds / total).clamp(0, 1),
              child: Container(height: 3, color: OverMedia.ink),
            ),
          ],
        ),
      );
    },
  );
}

class _Window extends StatelessWidget {
  const _Window({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width < 600
      ? SizedBox.expand(child: child)
      : AspectRatio(aspectRatio: 9 / 16, child: child);
}

/// The same places as a short, in bones of light.
class ShortSkeleton extends StatelessWidget {
  const ShortSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: OverMedia.bone, borderRadius: BorderRadius.circular(6)),
    );
    return ColoredBox(
      color: OverMedia.night,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(110, 14), bar(240, 22), bar(180, 22), bar(150, 44)],
            ),
          ),
        ],
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.again});

  final VoidCallback again;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NewsIcon(NewsIcons.circleCheck, size: 56, color: OverMedia.soft, stroke: 1.25),
            const SizedBox(height: 20),
            Text(
              s.shortsEnd,
              textAlign: TextAlign.center,
              style: context.type.headlineM.copyWith(color: OverMedia.ink),
            ),
            const SizedBox(height: 8),
            Text(
              s.shortsEndBody,
              textAlign: TextAlign.center,
              style: context.type.bodyM.copyWith(color: OverMedia.soft),
            ),
            const SizedBox(height: 24),
            NewsButton(s.watchAgain, kind: ButtonKind.secondary, onTap: again),
          ],
        ),
      ),
    );
  }
}
