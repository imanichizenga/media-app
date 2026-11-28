import 'dart:ui' as ui;

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        BottomNavigationBarItem,
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        CupertinoAlertDialog,
        CupertinoDialogAction,
        CupertinoSearchTextField,
        OverlayVisibilityMode,
        CupertinoSliverNavigationBar,
        CupertinoSliverRefreshControl,
        CupertinoTabBar,
        showCupertinoDialog,
        showCupertinoModalPopup;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../l10n/gen/strings.dart';
import '../components/basics.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';

/// Where the two platforms part ways, and the only place that asks which one this is (ADR-0044).
extension Native on BuildContext {
  bool get isApple => switch (Theme.of(this).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
}

/// Glass on iOS, solid ground on Android.
class BarGround extends StatelessWidget {
  const BarGround({super.key, required this.color, required this.child, this.top, this.bottom});

  final Color color;
  final Widget child;
  final BorderSide? top;
  final BorderSide? bottom;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: context.isApple ? color.withValues(alpha: 0.86) : color,
        border: Border(top: top ?? BorderSide.none, bottom: bottom ?? BorderSide.none),
      ),
      child: child,
    );
    if (!context.isApple) return box;
    return ClipRect(
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: box),
    );
  }
}

/// A list one can pull to refresh, in the platform's own way.
class NewsScroll extends StatelessWidget {
  const NewsScroll({
    super.key,
    required this.slivers,
    this.header = const [],
    this.controller,
    this.onRefresh,
    this.edge = 0,
    this.storage,
  });

  /// Above what is pulled.
  final List<Widget> header;
  final List<Widget> slivers;
  final ScrollController? controller;
  final Future<void> Function()? onRefresh;

  /// How far down Android's indicator begins.
  final double edge;
  final Key? storage;

  @override
  Widget build(BuildContext context) {
    final refresh = onRefresh;
    Future<void> pulled() {
      HapticFeedback.mediumImpact();
      return refresh!();
    }

    final apple = context.isApple;
    final view = CustomScrollView(
      key: storage,
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      scrollCacheExtent: const ScrollCacheExtent.pixels(900),
      slivers: [
        ...header,
        if (apple && refresh != null) CupertinoSliverRefreshControl(onRefresh: pulled),
        ...slivers,
        // Content runs under the bars; its end does not.
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).bottom + NewsSpace.s10),
        ),
      ],
    );
    if (apple || refresh == null) return view;
    return RefreshIndicator(
      onRefresh: pulled,
      edgeOffset: edge,
      color: context.colors.textPrimary,
      backgroundColor: context.colors.surfaceRaised,
      child: view,
    );
  }
}

/// The way back, drawn as the platform draws it.
NewsIconData backIcon(BuildContext context) =>
    context.isApple ? NewsIcons.chevronLeft : NewsIcons.arrowLeft;

/// The name of a place or a list: a large title that collapses on iOS; on Android a small top app bar that comes back
/// with a look up, medium where there is a way back.
class PlaceBar extends StatelessWidget {
  const PlaceBar(this.title, {super.key, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Below the status bar, at rest: where a refresh indicator begins.
  static const extent = 108.0;
  static const small = 60.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final back = onBack == null
        ? null
        : RoundButton(backIcon(context), label: Strings.of(context).back, onTap: onBack);
    Widget name(double size) => Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.type.headlineM.copyWith(color: c.textPrimary, fontSize: size, height: 1.15),
      ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: context.isApple
          ? CupertinoSliverNavigationBar(
              largeTitle: name(32),
              middle: ExcludeSemantics(child: name(18)),
              alwaysShowMiddle: false,
              automaticallyImplyLeading: false,
              transitionBetweenRoutes: false,
              padding: const EdgeInsetsDirectional.only(start: 4, end: 4),
              leading: back,
              trailing: trailing,
              stretch: true,
              backgroundColor: c.bg.withValues(alpha: 0.86),
              border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
            )
          : back == null
          ? SliverAppBar(
              title: name(26),
              automaticallyImplyLeading: false,
              floating: true,
              snap: true,
              centerTitle: false,
              titleSpacing: NewsSpace.s5,
              toolbarHeight: small,
              actions: [
                ?trailing,
                const SizedBox(width: NewsSpace.s1),
              ],
              backgroundColor: c.bg,
              surfaceTintColor: OverMedia.clear,
              shadowColor: OverMedia.clear,
              systemOverlayStyle: overlayFor(c.bg),
            )
          : SliverAppBar.medium(
              title: name(24),
              automaticallyImplyLeading: false,
              leading: back,
              leadingWidth: 52,
              titleSpacing: 0,
              toolbarHeight: 56,
              collapsedHeight: 56,
              expandedHeight: extent,
              actions: [
                ?trailing,
                const SizedBox(width: NewsSpace.s1),
              ],
              backgroundColor: c.bg,
              surfaceTintColor: OverMedia.clear,
              shadowColor: OverMedia.clear,
              systemOverlayStyle: overlayFor(c.bg),
              shape: Border(bottom: BorderSide(color: c.border, width: 0.5)),
            ),
    );
  }
}

/// One of the five places.
class Place {
  const Place(this.icon, this.name, {this.solid = false, this.count = 0, this.initial});

  final NewsIconData icon;
  final String name;

  /// Whether its filled form is still the icon.
  final bool solid;

  /// A number on its corner (stories saved), so one remembers there is something there; 0 shows nothing.
  final int count;

  /// The signed-in reader's initial, in place of the icon (You).
  final String? initial;
}

/// A place's icon with what it carries: the reader's initial, or a count on its corner. Sized as the icon, so nothing
/// moves when either arrives; the count pops when it changes.
class PlaceIcon extends StatelessWidget {
  const PlaceIcon({super.key, required this.place, required this.icon, required this.active});

  final Place place;
  final Widget icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = place.initial == null
        ? icon
        : Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.brand,
              shape: BoxShape.circle,
              border: active ? Border.all(color: c.navActive, width: 2) : null,
            ),
            child: Text(
              place.initial!,
              style: context.type.caption.copyWith(
                color: c.onBrand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          );
    if (place.count == 0) return base;
    final n = place.count > 99 ? '99+' : '${place.count}';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        base,
        Positioned(
          top: -4,
          right: -8,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(place.count),
            tween: Tween(begin: context.still ? 1 : 1.4, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: c.navBg, width: 2),
              ),
              child: Text(
                n,
                style: context.type.caption.copyWith(
                  color: c.onBrand,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The five places at the foot: Material's bar with its pill, or iOS's translucent one with a filled icon.
class PlacesBar extends StatelessWidget {
  const PlacesBar({
    super.key,
    required this.places,
    required this.at,
    required this.onGo,
    this.dark = false,
  });

  final List<Place> places;
  final int at;
  final ValueChanged<int> onGo;

  /// Beneath Shorts, which are dark in every theme.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ground = dark ? OverMedia.ground : c.navBg;
    final on = dark ? OverMedia.ink : c.navActive;
    final off = dark ? OverMedia.soft : c.navFg;
    final edge = BorderSide(color: dark ? OverMedia.faint : c.border, width: 0.5);
    Widget icon(int i, bool active) => PlaceIcon(
      place: places[i],
      active: active,
      icon: NewsIcon(
        places[i].icon,
        size: 24,
        color: active ? on : off,
        stroke: active ? 2.1 : 1.7,
        filled: active && places[i].solid,
      ),
    );
    TextStyle label(bool active, double size) => context.type.caption.copyWith(
      color: active ? on : off,
      fontSize: size,
      height: 1.2,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      fontVariations: [FontVariation('wght', active ? 600 : 500)],
    );
    if (context.isApple) {
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: CupertinoTabBar(
          currentIndex: at,
          onTap: onGo,
          height: 52,
          activeColor: on,
          inactiveColor: off,
          backgroundColor: ground.withValues(alpha: dark ? 1 : 0.86),
          border: Border(top: edge),
          items: [
            for (var i = 0; i < places.length; i++)
              BottomNavigationBarItem(
                icon: Padding(padding: const EdgeInsets.only(top: 5), child: icon(i, false)),
                activeIcon: Padding(padding: const EdgeInsets.only(top: 5), child: icon(i, true)),
                label: places[i].name,
              ),
          ],
        ),
      );
    }
    // Material 3's roles (R5): the active place's icon in the brand on a soft brand pill, every label in ink.
    final roles = AndroidPlaces.of(c, dark: dark);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        border: Border(top: edge),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith(
              (s) => label(
                s.contains(WidgetState.selected),
                11.5,
              ).copyWith(color: s.contains(WidgetState.selected) ? roles.label : off),
            ),
          ),
          child: NavigationBar(
            selectedIndex: at,
            onDestinationSelected: onGo,
            height: 64,
            elevation: 0,
            backgroundColor: OverMedia.clear,
            surfaceTintColor: OverMedia.clear,
            indicatorColor: roles.indicator,
            animationDuration: context.still ? Duration.zero : NewsMotion.slow,
            destinations: [
              for (var i = 0; i < places.length; i++)
                NavigationDestination(
                  icon: icon(i, false),
                  selectedIcon: icon(i, true),
                  label: places[i].name,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The colours of Android's bar of places, from the theme's tokens. The active icon is the brand (`navActive`); its
/// pill is the brand's soft container, or the brand over the bar where the bar is dark in a light theme (Bold Ink);
/// the active label is ink, never red. Tested for contrast in every theme.
class AndroidPlaces {
  const AndroidPlaces({required this.indicator, required this.label});

  factory AndroidPlaces.of(NewsColors c, {bool dark = false}) {
    if (dark) {
      return const AndroidPlaces(indicator: OverMedia.faint, label: OverMedia.ink);
    }
    final darkBar = c.navBg.computeLuminance() < 0.18;
    final darkTheme = c.surface.computeLuminance() < 0.18;
    return AndroidPlaces(
      indicator: darkBar && !darkTheme
          ? Color.alphaBlend(c.navActive.withValues(alpha: 0.24), c.navBg)
          : c.brandSoft,
      label: darkBar && !darkTheme ? OverMedia.ink : c.textPrimary,
    );
  }

  final Color indicator;
  final Color label;
}

/// The platform's switch, in ink.
class NewsSwitch extends StatelessWidget {
  const NewsSwitch({super.key, required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Switch.adaptive(
      value: on,
      onChanged: (v) {
        HapticFeedback.lightImpact();
        onChanged(v);
      },
      activeTrackColor: c.textPrimary,
      activeThumbColor: c.bg,
      inactiveTrackColor: context.isApple ? null : c.surfaceSunken,
      inactiveThumbColor: context.isApple ? null : c.borderStrong,
      trackOutlineColor: context.isApple ? null : WidgetStatePropertyAll(c.borderStrong),
    );
  }
}

/// Yes or no, asked the platform's way.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  required String no,
}) async {
  final c = context.colors;
  final type = context.type;
  final heading = type.title.copyWith(color: c.textPrimary, fontSize: 17);
  final words = type.bodyM.copyWith(color: c.textSecondary, fontSize: 14.5, height: 1.4);
  final bool? answer;
  if (context.isApple) {
    answer = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title, style: heading),
        content: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(body, style: words),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: Text(no, style: type.title.copyWith(color: c.textPrimary)),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(yes, style: type.title.copyWith(color: c.danger)),
          ),
        ],
      ),
    );
  } else {
    answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: OverMedia.clear,
        title: Text(title, style: type.headlineS.copyWith(color: c.textPrimary)),
        content: Text(body, style: words),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(no, style: type.label.copyWith(color: c.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(yes, style: type.label.copyWith(color: c.danger)),
          ),
        ],
      ),
    );
  }
  return answer ?? false;
}

/// One of a few: an action sheet on iOS, a list in a bottom sheet on Android.
Future<T?> choose<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T current,
}) {
  final c = context.colors;
  final type = context.type;
  if (context.isApple) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title, style: type.caption.copyWith(color: c.textSecondary)),
        actions: [
          for (final (value, name) in options)
            CupertinoActionSheetAction(
              isDefaultAction: value == current,
              onPressed: () => Navigator.pop(context, value),
              child: Semantics(
                selected: value == current,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, style: type.title.copyWith(color: c.textPrimary, fontSize: 18)),
                    if (value == current) ...[
                      const SizedBox(width: 8),
                      NewsIcon(NewsIcons.check, size: 18, color: c.textPrimary),
                    ],
                  ],
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(
            Strings.of(context).cancel,
            style: type.title.copyWith(color: c.textPrimary, fontSize: 18),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Semantics(
              header: true,
              child: Text(title, style: type.headlineS.copyWith(color: c.textPrimary)),
            ),
          ),
          for (final (value, name) in options)
            Semantics(
              inMutuallyExclusiveGroup: true,
              checked: value == current,
              child: InkWell(
                onTap: () => Navigator.pop(context, value),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(name, style: type.bodyL.copyWith(color: c.textPrimary)),
                      ),
                      if (value == current)
                        NewsIcon(NewsIcons.check, size: 22, color: c.textPrimary),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// Rows that belong together: inset and grouped on iOS, a plain list under a label on Android.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.rows, this.note});

  final String? title;
  final String? note;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final apple = context.isApple;
    final side = apple ? NewsSpace.s4 : 0.0;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (apple && i > 0)
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Divider(color: c.border, height: 0.5, thickness: 0.5),
            ),
          row,
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, apple ? 24 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(apple ? 16 : NewsSpace.s5, 8, 16, apple ? 6 : 4),
              child: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: context.type.label.copyWith(
                    color: c.textSecondary,
                    fontSize: apple ? 13 : 14,
                  ),
                ),
              ),
            ),
          if (apple)
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: list,
            )
          else
            list,
          if (note != null)
            Padding(
              padding: EdgeInsets.fromLTRB(apple ? 16 : NewsSpace.s5, 6, 16, 4),
              child: Text(note!, style: context.type.caption.copyWith(color: c.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
    this.toggled,
    this.color,
  });

  final NewsIconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? toggled;

  /// A row that ends something (delete): its icon and words in this colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final apple = context.isApple;
    final words = context.type.bodyM.copyWith(color: color ?? c.textPrimary, fontSize: 16);
    final soft = context.type.bodyM.copyWith(color: c.textSecondary, fontSize: apple ? 16 : 14);
    final row = Container(
      constraints: BoxConstraints(minHeight: apple ? 48 : 56),
      padding: EdgeInsets.symmetric(horizontal: apple ? 16 : NewsSpace.s5, vertical: 6),
      child: Row(
        children: [
          NewsIcon(icon, size: 20, color: color ?? c.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: apple || value == null
                ? Text(title, style: words)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: words),
                      Text(value!, style: soft),
                    ],
                  ),
          ),
          if (apple && value != null) ...[
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(value!, style: soft, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (trailing != null)
            trailing!
          else if (apple && onTap != null) ...[
            const SizedBox(width: 6),
            NewsIcon(NewsIcons.chevronRight, size: 18, color: c.textTertiary),
          ],
        ],
      ),
    );
    if (onTap == null && toggled == null) return row;
    return MergeSemantics(
      child: Semantics(
        button: toggled == null,
        toggled: toggled,
        child: apple
            ? Pressable(onTap: onTap, scale: 1, child: row)
            : Material(
                color: OverMedia.clear,
                child: InkWell(onTap: onTap, child: row),
              ),
      ),
    );
  }
}

/// What one can do with the thing that was held: a menu with its preview on iOS, a bottom sheet on Android.
Future<void> showActions(
  BuildContext context, {
  required Widget preview,
  required List<(NewsIconData, String, VoidCallback)> actions,
}) {
  HapticFeedback.lightImpact();
  final c = context.colors;
  final type = context.type;
  Widget rows(BuildContext context, {required bool divided}) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, (icon, name, act)) in actions.indexed) ...[
        if (divided && i > 0) Divider(color: c.border, height: 0.5, thickness: 0.5),
        Material(
          color: OverMedia.clear,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              act();
            },
            child: Container(
              constraints: BoxConstraints(minHeight: divided ? 48 : 56),
              padding: EdgeInsets.symmetric(horizontal: divided ? 16 : 24, vertical: 8),
              child: Row(
                children: [
                  if (!divided) ...[
                    NewsIcon(icon, size: 22, color: c.textPrimary),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Text(name, style: type.bodyL.copyWith(color: c.textPrimary)),
                  ),
                  if (divided) NewsIcon(icon, size: 20, color: c.textPrimary),
                ],
              ),
            ),
          ),
        ),
      ],
    ],
  );
  if (!context.isApple) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: rows(context, divided: false),
        ),
      ),
    );
  }
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: Strings.of(context).close,
      transitionDuration: NewsMotion.base,
      pageBuilder: (context, _, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: ColoredBox(
            color: c.bg.withValues(alpha: 0.5),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Float(
                          child: IgnorePointer(
                            child: Padding(padding: const EdgeInsets.all(12), child: preview),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(width: 240, child: _Float(child: rows(context, divided: true))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ),
  );
}

class _Float extends StatelessWidget {
  const _Float({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: OverMedia.shadow),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(color: context.colors.surfaceRaised, child: child),
    ),
  );
}

/// The search field: iOS's own, or Material's rounded one with the same parts (a magnifier, the words, a clear button).
class NativeSearchField extends StatelessWidget {
  const NativeSearchField({
    super.key,
    required this.controller,
    required this.focus,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final c = context.colors;
    final style = context.type.bodyL.copyWith(color: c.textPrimary);
    void clear() {
      controller.clear();
      onChanged('');
      focus.requestFocus();
    }

    final field = context.isApple
        // The app carries no icon font: the magnifier and the clear mark are its own drawings.
        ? ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Stack(
              alignment: Alignment.centerRight,
              children: [
                CupertinoSearchTextField(
                  controller: controller,
                  focusNode: focus,
                  placeholder: s.searchPlaceholder,
                  style: style,
                  prefixIcon: NewsIcon(NewsIcons.search, size: 18, color: c.textSecondary),
                  suffixMode: OverlayVisibilityMode.never,
                  padding: EdgeInsetsDirectional.fromSTEB(
                    6,
                    10,
                    controller.text.isEmpty ? 6 : 40,
                    10,
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
                if (controller.text.isNotEmpty)
                  Pressable(
                    label: s.searchClear,
                    onTap: clear,
                    child: SizedBox.square(
                      dimension: 40,
                      child: Center(child: NewsIcon(NewsIcons.x, size: 18, color: c.textSecondary)),
                    ),
                  ),
              ],
            ),
          )
        : ListenableBuilder(
            listenable: controller,
            builder: (context, _) => TextField(
              controller: controller,
              focusNode: focus,
              style: style,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: s.searchPlaceholder,
                filled: true,
                fillColor: c.surfaceSunken,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: NewsIcon(NewsIcons.search, size: 20, color: c.textSecondary),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 48),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: s.searchClear,
                        onPressed: clear,
                        icon: NewsIcon(NewsIcons.x, size: 20, color: c.textSecondary),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );
    return Semantics(textField: true, label: s.searchLabel, child: field);
  }
}
