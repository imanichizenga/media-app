import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../tokens/theme.dart';

/// One slow sweep shared by every bone on the screen. Still under reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.sweep;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.still ? _controller.stop() : _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ShimmerScope(sweep: context.still ? null : _controller, child: widget.child);
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.sweep, required super.child});

  final Animation<double>? sweep;

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.sweep != sweep;
}

/// The absence of content, in its exact shape.
class Bone extends StatelessWidget {
  const Bone({super.key, required this.width, required this.height, this.radius = 6});
  const Bone.fill({super.key}) : width = null, height = null, radius = 0;

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final sweep = Shimmer.of(context);
    BoxDecoration paint(double t) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: sweep == null ? c.skeleton : null,
      gradient: sweep == null
          ? null
          : LinearGradient(
              begin: Alignment(-3 + 4 * t, 0),
              end: Alignment(-1 + 4 * t, 0),
              colors: [c.skeleton, c.skeletonShine, c.skeleton],
            ),
    );
    final box = sweep == null
        ? DecoratedBox(decoration: paint(0))
        : AnimatedBuilder(
            animation: sweep,
            builder: (_, _) => DecoratedBox(decoration: paint(sweep.value)),
          );
    return ExcludeSemantics(
      child: width == null && height == null
          ? SizedBox.expand(child: box)
          : SizedBox(width: width, height: height, child: box),
    );
  }
}

/// Text, or bones in the same line boxes: the reason a skeleton cannot drift from its component.
class TextOrBone extends StatelessWidget {
  const TextOrBone(
    this.text, {
    super.key,
    required this.style,
    this.lines = 1,
    this.maxLines,
    this.last = 0.6,
    this.align,
  });

  final String? text;
  final TextStyle style;

  /// How many lines of bones, and how much of the last one.
  final int lines;
  final int? maxLines;
  final double last;
  final TextAlign? align;

  @override
  Widget build(BuildContext context) {
    if (text != null) {
      return Text(
        text!,
        style: style,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        textAlign: align,
      );
    }
    final size = MediaQuery.textScalerOf(context).scale(style.fontSize!);
    final line = size * (style.height ?? 1.2);
    return LayoutBuilder(
      builder: (context, box) {
        final full = box.maxWidth.isFinite ? box.maxWidth : size * 8;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines; i++)
              SizedBox(
                height: line,
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  child: Bone(
                    width: i == lines - 1 ? full * last : full,
                    height: size * 0.72,
                    radius: NewsRadius.sm / 2,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
