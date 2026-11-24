import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../core/config/app_config.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/telemetry/analytics.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/picture.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../content/feeds.dart';
import '../explore/explore_screen.dart' show categoryIcons;

/// Shown once: welcome, language, topics. Skip is always there, always in the same place.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.step = 0});

  final int step;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late int _step = widget.step;

  void _finish({required bool skipped}) {
    final topics = ref.read(settingsControllerProvider).topics.length;
    ref.read(analyticsProvider).track(OnboardingFinished(skipped: skipped, topics: topics));
    ref.read(settingsControllerProvider.notifier).change((x) => x.copyWith(onboarded: true));
    const HomeRoute().go(context);
  }

  void _next() => _step == 2 ? _finish(skipped: false) : setState(() => _step++);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0,
    onPopInvokedWithResult: (popped, _) {
      if (!popped) setState(() => _step--);
    },
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(_step == 0 ? OverMedia.ground : context.colors.bg),
      child: Scaffold(
        backgroundColor: _step == 0 ? OverMedia.ground : null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: context.still ? Duration.zero : NewsMotion.slow,
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  0 => _Welcome(onNext: _next),
                  1 => _Language(onNext: _next),
                  _ => _Topics(onNext: _next),
                },
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              right: 20,
              child: SkipPill(onTap: () => _finish(skipped: true)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Its own ground, so it reads over any picture.
class SkipPill extends StatelessWidget {
  const SkipPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          Strings.of(context).skip,
          style: context.type.label.copyWith(color: OverMedia.ink),
        ),
      ),
    ),
  );
}

class _Welcome extends ConsumerWidget {
  const _Welcome({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final h = ref.watch(homeFeedProvider).value?.value;
    final pictures = [
      for (final Story x in [...?h?.lead, ...?h?.latest])
        if (x.image != null && !x.isSensitive) x.image!,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(child: _Wall(pictures)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.3, 0.56, 1],
              colors: [
                Color(0x66000000),
                Color(0x1A000000),
                Color(0xD9000000),
                Color(0xFF000000),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              reverse: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 120, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Wordmark(size: 24, onDark: true, color: OverMedia.ink),
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          s.welcomeTitle,
                          style: context.type.display.copyWith(
                            color: OverMedia.ink,
                            fontSize: 44,
                            height: 1.06,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        s.welcomeBody,
                        style: context.type.bodyL.copyWith(color: OverMedia.soft, height: 1.45),
                      ),
                      const SizedBox(height: 28),
                      NewsButton(s.start, wide: true, onTap: onNext),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Today's pictures, drifting slowly. Still under reduced motion.
class _Wall extends StatefulWidget {
  const _Wall(this.pictures);

  final List<PublicImage> pictures;

  @override
  State<_Wall> createState() => _WallState();
}

class _WallState extends State<_Wall> with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.still ? _drift.stop() : _drift.repeat(reverse: true);
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pictures;
    Widget column(int from, double shift, double direction) => Expanded(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, shift + direction * 60 * _drift.value),
          child: child,
        ),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Column(
            children: [
              for (var i = 0; i < 5; i++)
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: AspectRatio(
                    aspectRatio: 0.82,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: p.isEmpty
                          ? const ColoredBox(color: Color(0xFF1C1C1C))
                          : NewsPicture(p[(from + i * 2) % p.length]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return ClipRect(
      child: Transform.rotate(
        angle: -4 * math.pi / 180,
        child: Transform.scale(
          scale: 1.16,
          child: Row(
            children: [column(0, -40, -1), column(1, -130, 1)],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.at,
    required this.title,
    required this.body,
    required this.child,
    required this.action,
    required this.onNext,
    this.note,
  });

  final int at;
  final String title;
  final String body;
  final Widget child;
  final String action;
  final VoidCallback onNext;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 48,
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        for (var i = 0; i < 2; i++)
                          AnimatedContainer(
                            duration: NewsMotion.base,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == at ? 36 : 16,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= at ? c.textPrimary : c.border,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: context.type.display.copyWith(
                              color: c.textPrimary,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          body,
                          style: context.type.bodyL.copyWith(
                            color: c.textSecondary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        child,
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (note != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      note!,
                      textAlign: TextAlign.center,
                      style: context.type.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                NewsButton(action, wide: true, onTap: onNext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Language extends ConsumerWidget {
  const _Language({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final locale = ref.watch(localeNameProvider);
    Widget choice(String code, String name, String hello) {
      final on = code == locale;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: on,
          child: Pressable(
            haptic: true,
            onTap: () => ref
                .read(settingsControllerProvider.notifier)
                .change((x) => x.copyWith(locale: code)),
            child: AnimatedContainer(
              duration: context.still ? Duration.zero : NewsMotion.base,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: on ? c.textPrimary : c.surface,
                borderRadius: BorderRadius.circular(NewsRadius.xl),
                border: Border.all(color: on ? c.textPrimary : c.border, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: context.type.headlineM.copyWith(
                            color: on ? c.bg : c.textPrimary,
                          ),
                        ),
                        Text(
                          hello,
                          style: context.type.bodyM.copyWith(
                            color: on ? c.bg.withValues(alpha: 0.78) : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (on) NewsIcon(NewsIcons.check, size: 26, color: c.bg, stroke: 2.4),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _Step(
      at: 0,
      title: s.languageTitle,
      body: s.languageBody,
      action: s.next,
      onNext: onNext,
      child: Column(
        children: [
          choice('sw', 'Kiswahili', 'Karibu'),
          choice('en', 'English', 'Welcome'),
        ],
      ),
    );
  }
}

class _Topics extends ConsumerWidget {
  const _Topics({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final nav = ref.watch(navigationProvider).value?.value;
    final topics = ref.watch(settingsControllerProvider.select((x) => x.topics));
    return _Step(
      at: 1,
      title: s.topicsTitle,
      body: s.topicsBody,
      action: s.start,
      note: s.topicsChosen(topics.length),
      onNext: onNext,
      child: Shimmer(
        child: Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            if (nav == null)
              for (final w in const [120.0, 96.0, 140.0, 110.0, 128.0, 100.0, 150.0, 118.0])
                Bone(width: w, height: 48, radius: 28)
            else
              for (final n in nav)
                NewsChip(
                  n.name,
                  toggles: true,
                  icon: categoryIcons[n.icon] ?? NewsIcons.newspaper,
                  on: topics.contains(n.id),
                  onTap: () => ref
                      .read(settingsControllerProvider.notifier)
                      .change(
                        (x) => x.copyWith(
                          topics: x.topics.contains(n.id)
                              ? ({...x.topics}..remove(n.id))
                              : {...x.topics, n.id},
                        ),
                      ),
                ),
          ],
        ),
      ),
    );
  }
}
