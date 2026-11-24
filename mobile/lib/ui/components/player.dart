import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:video_player/video_player.dart';

import '../../core/format/format.dart';
import '../../core/network/images.dart';
import '../../l10n/gen/strings.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';
import 'basics.dart';
import 'picture.dart';

/// A video in the page. Nothing is fetched until it is tapped; the poster holds its place.
class NewsPlayer extends ConsumerStatefulWidget {
  const NewsPlayer({
    super.key,
    required this.hls,
    required this.poster,
    required this.label,
    this.color = '',
    this.ratio = 16 / 9,
    this.length,
    this.radius = NewsRadius.lg,
    this.onProgress,
  });

  final String hls;
  final String poster;
  final String label;
  final String color;
  final double ratio;
  final Duration? length;
  final double radius;
  final ValueChanged<int>? onProgress;

  @override
  ConsumerState<NewsPlayer> createState() => _NewsPlayerState();
}

class _NewsPlayerState extends ConsumerState<NewsPlayer> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_controller?.pause());
  }

  Future<void> _start() async {
    final url = ref.read(picturesProvider.notifier).address(widget.hls);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    setState(() {
      _failed = false;
      _controller = controller;
    });
    try {
      await controller.initialize();
      if (!mounted) return;
      controller.addListener(_watch);
      await controller.play();
      if (mounted) setState(() {});
    } on Object {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _controller = null;
      });
      unawaited(controller.dispose());
    }
  }

  int _reached = 0;
  void _watch() {
    final v = _controller!.value;
    if (v.duration == Duration.zero) return;
    final percent = (v.position.inMilliseconds * 100 / v.duration.inMilliseconds).floor();
    for (final mark in const [25, 50, 75, 100]) {
      if (percent >= mark && _reached < mark) {
        _reached = mark;
        widget.onProgress?.call(mark);
      }
    }
  }

  Future<void> _fullscreen() async {
    final controller = _controller!;
    final wide = controller.value.aspectRatio > 1;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (wide) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: NewsMotion.base,
        pageBuilder: (context, _, _) => Scaffold(
          backgroundColor: OverMedia.ground,
          body: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: _Surface(
                controller: controller,
                fullscreen: true,
                onFullscreen: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
    await SystemChrome.setPreferredOrientations(const []);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final controller = _controller;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AspectRatio(
          aspectRatio: widget.ratio,
          child: ColoredBox(
            color: OverMedia.ground,
            child: controller != null && controller.value.isInitialized
                ? _Surface(controller: controller, onFullscreen: _fullscreen)
                : Pressable(
                    onTap: controller == null ? _start : null,
                    label: '${_failed ? '${s.videoError}. ' : ''}${s.play}: ${widget.label}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.poster.isNotEmpty)
                          PosterPicture(poster: widget.poster, color: widget.color),
                        const DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
                        Center(child: BigPlay(pending: controller != null)),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Text(
                            _failed
                                ? '${s.videoError}. ${s.retry}'
                                : widget.length == null
                                ? ''
                                : clock(widget.length!),
                            style: context.type.label.copyWith(color: OverMedia.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The one play button.
class BigPlay extends StatelessWidget {
  const BigPlay({super.key, this.pending = false, this.size = 72});

  final bool pending;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: OverMedia.chip, shape: BoxShape.circle),
    child: pending
        // A pending state of a button, not a content loader.
        ? const SizedBox.square(
            dimension: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: OverMedia.ink),
          )
        : Padding(
            padding: EdgeInsets.only(left: size * 0.05),
            child: NewsIcon(NewsIcons.play, size: size * 0.4, filled: true, color: OverMedia.ink),
          ),
  );
}

class _Surface extends StatefulWidget {
  const _Surface({required this.controller, required this.onFullscreen, this.fullscreen = false});

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;
  final bool fullscreen;

  @override
  State<_Surface> createState() => _SurfaceState();
}

class _SurfaceState extends State<_Surface> {
  bool _shown = true;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _later();
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _later() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      // Someone moving through the controls by ear must not lose them.
      if (mounted &&
          widget.controller.value.isPlaying &&
          !MediaQuery.accessibleNavigationOf(context)) {
        setState(() => _shown = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final controller = widget.controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _shown = !_shown);
        _later();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
          IgnorePointer(
            ignoring: !_shown,
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration: NewsMotion.base,
              child: ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, v, _) {
                  final total = v.duration.inMilliseconds;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
                      Center(
                        child: RoundPlay(
                          playing: v.isPlaying,
                          onTap: () {
                            if (v.isPlaying) {
                              controller.pause();
                            } else {
                              if (v.position >= v.duration) controller.seekTo(Duration.zero);
                              controller.play();
                            }
                            _later();
                          },
                        ),
                      ),
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 2,
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              '${clock(v.position)} / ${clock(v.duration)}',
                              style: context.type.caption.copyWith(
                                color: OverMedia.ink,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: OverMedia.ink,
                                  inactiveTrackColor: OverMedia.faint,
                                  thumbColor: OverMedia.ink,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: total == 0
                                      ? 0
                                      : (v.position.inMilliseconds / total).clamp(0, 1),
                                  semanticFormatterCallback: (_) =>
                                      s.position(clock(v.position), clock(v.duration)),
                                  onChanged: (x) {
                                    controller.seekTo(v.duration * x);
                                    _later();
                                  },
                                ),
                              ),
                            ),
                            RoundButton(
                              v.volume == 0 ? NewsIcons.volumeX : NewsIcons.volume2,
                              label: v.volume == 0 ? s.unmute : s.mute,
                              color: OverMedia.ink,
                              onTap: () => controller.setVolume(v.volume == 0 ? 1 : 0),
                            ),
                            RoundButton(
                              widget.fullscreen ? NewsIcons.minimize : NewsIcons.maximize,
                              label: widget.fullscreen ? s.exitFullscreen : s.fullscreen,
                              color: OverMedia.ink,
                              onTap: widget.onFullscreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoundPlay extends StatelessWidget {
  const RoundPlay({super.key, required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    haptic: true,
    label: playing ? Strings.of(context).pause : Strings.of(context).play,
    child: Container(
      width: 68,
      height: 68,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: OverMedia.chip, shape: BoxShape.circle),
      child: NewsIcon(
        playing ? NewsIcons.pause : NewsIcons.play,
        size: 28,
        filled: true,
        color: OverMedia.ink,
      ),
    ),
  );
}
