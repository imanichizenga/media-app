import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/config/app_config.dart';
import '../../core/network/images.dart';
import '../tokens/news_icon.dart';
import '../tokens/news_icons.g.dart';
import '../tokens/theme.dart';

/// A surface that gives a little under the thumb. One stop for a screen reader.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.label,
    this.haptic = false,
    this.scale = 0.985,
    this.link = false,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Replaces what the child would say.
  final String? label;
  final bool haptic;
  final double scale;
  final bool link;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down && !context.still ? widget.scale : 1,
        duration: NewsMotion.fast,
        curve: NewsMotion.standard,
        child: AnimatedOpacity(
          opacity: _down ? 0.86 : 1,
          duration: NewsMotion.fast,
          child: widget.child,
        ),
      ),
    );
    return MergeSemantics(
      child: Semantics(
        button: !widget.link,
        link: widget.link,
        enabled: widget.onTap != null,
        label: widget.label,
        excludeSemantics: widget.label != null,
        onTap: widget.onTap,
        child: body,
      ),
    );
  }
}

enum ButtonKind { primary, secondary, quiet }

class NewsButton extends StatelessWidget {
  const NewsButton(
    this.text, {
    super.key,
    required this.onTap,
    this.kind = ButtonKind.primary,
    this.icon,
    this.wide = false,
    this.pending = false,
  });

  final String text;
  final VoidCallback? onTap;
  final ButtonKind kind;
  final NewsIconData? icon;
  final bool wide;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (ground, ink, edge) = switch (kind) {
      ButtonKind.primary => (c.brand, c.onBrand, c.brand),
      ButtonKind.secondary => (c.surface, c.textPrimary, c.borderStrong),
      ButtonKind.quiet => (OverMedia.clear, c.textPrimary, OverMedia.clear),
    };
    return Pressable(
      onTap: pending ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        width: wide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s6, vertical: NewsSpace.s3),
        decoration: BoxDecoration(
          color: ground,
          border: Border.all(color: edge, width: kind == ButtonKind.secondary ? 1 : 0),
          borderRadius: BorderRadius.circular(NewsRadius.lg),
        ),
        child: Row(
          mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[NewsIcon(icon!, size: 18, color: ink), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: context.type.title.copyWith(color: ink, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round button. Over pictures it brings its own ground.
class RoundButton extends StatelessWidget {
  const RoundButton(
    this.icon, {
    super.key,
    required this.label,
    required this.onTap,
    this.overMedia = false,
    this.filled = false,
    this.color,
    this.haptic = false,
  });

  final NewsIconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool overMedia;
  final bool filled;
  final Color? color;
  final bool haptic;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    haptic: haptic,
    scale: 0.92,
    child: SizedBox.square(
      dimension: 48,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: overMedia
              ? const BoxDecoration(color: OverMedia.chip, shape: BoxShape.circle)
              : null,
          alignment: Alignment.center,
          child: NewsIcon(
            icon,
            size: 22,
            filled: filled,
            color: color ?? (overMedia ? OverMedia.ink : context.colors.textPrimary),
          ),
        ),
      ),
    ),
  );
}

/// The logo from the admin, or the name in the serif.
class Wordmark extends ConsumerWidget {
  const Wordmark({super.key, this.size = 26, this.color, this.onDark});

  final double size;
  final Color? color;

  /// Null: judged by the masthead's own ground.
  final bool? onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandProvider);
    final c = context.colors;
    final dark = onDark ?? c.mastheadBg.computeLuminance() < 0.18;
    final logo = dark ? brand.dark : brand.light;
    if (logo != null) {
      final height = size * 1.15;
      final ratio = MediaQuery.devicePixelRatioOf(context);
      final name = ratio > 2 ? '3x' : (ratio > 1 ? '2x' : '1x');
      final address = logo.png[name] ?? logo.png.values.first;
      ref.watch(picturesProvider);
      return Image(
        image: ref.watch(pictureLoaderProvider)('${ref.watch(apiBaseProvider)}$address'),
        height: height,
        width: height * logo.width / logo.height,
        semanticLabel: brand.name,
        errorBuilder: (_, _, _) => _name(context, brand.name),
      );
    }
    return _name(context, brand.name);
  }

  Widget _name(BuildContext context, String name) => Text(
    name,
    maxLines: 1,
    style: context.type.headlineM.copyWith(
      fontSize: size,
      height: 1.15,
      letterSpacing: -size * 0.02,
      color: color ?? context.colors.wordmark,
    ),
  );
}

/// The serif title of a part of the page, over an ink rule.
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.onMore, this.more, this.padded = true});

  final String title;
  final VoidCallback? onMore;
  final String? more;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padded ? NewsSpace.s5 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 28, height: 3, color: c.textPrimary),
          const SizedBox(height: NewsSpace.s1),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.type.headlineM.copyWith(color: c.textPrimary)),
                ),
              ),
              if (onMore != null)
                Pressable(
                  onTap: onMore,
                  label: '${more ?? ''}: $title',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          more ?? '',
                          style: context.type.label.copyWith(color: c.textSecondary),
                        ),
                        NewsIcon(NewsIcons.chevronRight, size: 16, color: c.textSecondary),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 48),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two or three choices with a thumb that slides between them.
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.labels,
    required this.at,
    required this.onChanged,
    this.onDark = false,
  });

  final List<String> labels;
  final int at;
  final ValueChanged<int> onChanged;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ground = onDark ? OverMedia.chip : c.surfaceSunken;
    final thumb = onDark ? OverMedia.ink : c.surfaceRaised;
    // Large text needs the whole width for each choice: one under another, nothing cut.
    if (labels.length > 2 && MediaQuery.textScalerOf(context).scale(10) > 14) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, label) in labels.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: NewsChip(label, on: i == at, toggles: true, onTap: () => onChanged(i)),
            ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: ground, borderRadius: BorderRadius.circular(30)),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: context.still ? Duration.zero : NewsMotion.slow,
              curve: NewsMotion.standard,
              alignment: Alignment(labels.length == 1 ? 0 : -1 + 2 * at / (labels.length - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: thumb,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: context.isDark || onDark ? null : OverMedia.lift,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final (i, label) in labels.indexed)
                Expanded(
                  child: Semantics(
                    inMutuallyExclusiveGroup: true,
                    selected: i == at,
                    child: Pressable(
                      onTap: () => onChanged(i),
                      haptic: true,
                      scale: 1,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.label.copyWith(
                            color: i == at
                                ? (onDark ? OverMedia.ground : c.textPrimary)
                                : (onDark ? OverMedia.soft : c.textSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A word one can choose or follow.
class NewsChip extends StatelessWidget {
  const NewsChip(
    this.label, {
    super.key,
    required this.onTap,
    this.on = false,
    this.icon,
    this.toggles = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool on;
  final NewsIconData? icon;
  final bool toggles;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ink = on ? c.bg : c.textPrimary;
    return Semantics(
      selected: toggles ? on : null,
      child: Pressable(
        onTap: onTap,
        haptic: toggles,
        scale: 0.96,
        child: AnimatedContainer(
          duration: context.still ? Duration.zero : NewsMotion.base,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: on ? c.textPrimary : c.surfaceSunken,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                NewsIcon(icon!, size: 18, color: ink),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label, style: context.type.label.copyWith(color: ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
