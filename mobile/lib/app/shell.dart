import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/account/session.dart';
import '../features/saved/library.dart';
import '../features/video/video_screen.dart';
import '../l10n/gen/strings.dart';
import '../ui/adaptive/adaptive.dart';
import '../ui/adaptive/tops.dart';
import '../ui/components/basics.dart';
import '../ui/tokens/news_icon.dart';
import '../ui/tokens/news_icons.g.dart';
import '../ui/tokens/theme.dart';
import 'router.dart';
import 'window.dart';

List<Place> placesOf(Strings s, {int saved = 0, String? initial}) => [
  Place(NewsIcons.house, s.navHome, solid: true),
  Place(NewsIcons.play, s.navVideo, solid: true),
  Place(NewsIcons.compass, s.navExplore),
  Place(NewsIcons.bookmark, s.navSaved, solid: true, count: saved),
  Place(NewsIcons.circleUser, s.navYou, initial: initial),
];

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _tops = Tops();

  /// Another place; or the top of this one; or, already there, its root.
  void _go(int i) {
    HapticFeedback.selectionClick();
    if (i != widget.shell.currentIndex) return widget.shell.goBranch(i);
    if (!_tops.go(i)) branchKeys[i].currentState?.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final at = widget.shell.currentIndex;
    // Shorts are dark in every theme, and so is the bar beneath them.
    final dark = at == 1 && ref.watch(videoTabProvider) == 0;
    final shell = TopsScope(tops: _tops, at: at, child: widget.shell);
    if (windowOf(context) == WindowClass.expanded) {
      return Scaffold(
        body: Row(
          children: [
            NavRail(at: at, onGo: _go, dark: dark),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(dark ? OverMedia.ground : c.navBg),
      child: Scaffold(
        backgroundColor: dark ? OverMedia.ground : c.bg,
        extendBody: !dark,
        body: shell,
        bottomNavigationBar: PlacesBar(
          places: placesOf(
            Strings.of(context),
            saved: ref.watch(savedStoriesProvider.select((v) => v.value?.length ?? 0)),
            initial: ref.watch(readerProvider.select((r) => r?.initial)),
          ),
          at: at,
          onGo: _go,
          dark: dark,
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
    final places = placesOf(Strings.of(context));
    return Container(
      width: 96,
      decoration: BoxDecoration(
        color: dark ? OverMedia.ground : c.navBg,
        border: Border(right: BorderSide(color: dark ? OverMedia.faint : c.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 24),
      child: Column(
        children: [
          for (final (i, place) in places.indexed)
            SizedBox(
              height: 76,
              width: 96,
              child: _RailItem(place, on: i == at, dark: dark, onTap: () => onGo(i)),
            ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem(this.place, {required this.on, required this.dark, required this.onTap});

  final Place place;
  final bool on;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = dark ? (on ? OverMedia.ink : OverMedia.soft) : (on ? c.navActive : c.navFg);
    return Semantics(
      selected: on,
      child: Pressable(
        onTap: onTap,
        label: place.name,
        scale: 0.94,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !on
                      ? OverMedia.clear
                      : dark
                      ? OverMedia.faint
                      : c.navActive.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: NewsIcon(
                  place.icon,
                  size: 24,
                  color: ink,
                  stroke: on ? 2.1 : 1.7,
                  filled: on && place.solid,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                place.name,
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
