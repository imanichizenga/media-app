import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../features/video/video_screen.dart';
import '../l10n/gen/strings.dart';
import '../ui/components/basics.dart';
import '../ui/tokens/news_icon.dart';
import '../ui/tokens/news_icons.g.dart';
import '../ui/tokens/theme.dart';
import 'window.dart';

/// Tapping the place one is in goes back to its top.
final tabAgain = List.generate(5, (_) => ValueNotifier<int>(0));

const _icons = [
  NewsIcons.house,
  NewsIcons.play,
  NewsIcons.compass,
  NewsIcons.bookmark,
  NewsIcons.circleUser,
];

/// Icons whose filled form is still the icon.
const _solid = {0, 1, 3};

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _go(int i) {
    HapticFeedback.selectionClick();
    if (i == shell.currentIndex) tabAgain[i].value++;
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    // Shorts are dark in every theme, and so is the bar beneath them.
    final dark = shell.currentIndex == 1 && ref.watch(videoTabProvider) == 0;
    final wide = windowOf(context) == WindowClass.expanded;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavRail(at: shell.currentIndex, onGo: _go, dark: dark),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(dark ? OverMedia.ground : c.navBg),
      child: Scaffold(
        backgroundColor: dark ? OverMedia.ground : c.bg,
        body: shell,
        bottomNavigationBar: BottomBar(at: shell.currentIndex, onGo: _go, dark: dark),
      ),
    );
  }
}

List<String> _names(Strings s) => [s.navHome, s.navVideo, s.navExplore, s.navSaved, s.navYou];

class _NavItem extends StatelessWidget {
  const _NavItem({required this.i, required this.on, required this.onGo, required this.dark});

  final int i;
  final bool on;
  final ValueChanged<int> onGo;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = dark
        ? (on ? OverMedia.ink : OverMedia.soft)
        : (on ? c.navActive : c.navFg);
    return Semantics(
      selected: on,
      child: Pressable(
        onTap: () => onGo(i),
        label: _names(Strings.of(context))[i],
        scale: 0.92,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NewsIcon(
                _icons[i],
                size: 24,
                color: ink,
                stroke: on ? 2.1 : 1.7,
                filled: on && _solid.contains(i),
              ),
              const SizedBox(height: 3),
              Text(
                _names(Strings.of(context))[i],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: ink,
                  fontSize: 11.5,
                  height: 1.3,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  fontVariations: [FontVariation('wght', on ? 600 : 500)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Five places. The mark slides to the one you are in.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.at, required this.onGo, this.dark = false});

  final int at;
  final ValueChanged<int> onGo;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: dark ? OverMedia.ground : c.navBg,
        border: Border(top: BorderSide(color: dark ? OverMedia.faint : c.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: context.still ? Duration.zero : NewsMotion.slow,
              curve: NewsMotion.standard,
              alignment: Alignment(-1 + 2 * at / 4, -1),
              child: FractionallySizedBox(
                widthFactor: 0.2,
                child: Center(
                  heightFactor: 1,
                  child: Container(
                    width: 28,
                    height: 3,
                    decoration: BoxDecoration(
                      color: dark ? OverMedia.ink : c.navActive,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Expanded(
                    child: SizedBox.expand(
                      child: _NavItem(i: i, on: i == at, onGo: onGo, dark: dark),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The same five, at the left edge of a wide window.
class NavRail extends StatelessWidget {
  const NavRail({super.key, required this.at, required this.onGo, this.dark = false});

  final int at;
  final ValueChanged<int> onGo;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: dark ? OverMedia.ground : c.navBg,
        border: Border(right: BorderSide(color: dark ? OverMedia.faint : c.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 24),
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            SizedBox(
              height: 76,
              width: 96,
              child: _NavItem(i: i, on: i == at, onGo: onGo, dark: dark),
            ),
        ],
      ),
    );
  }
}
