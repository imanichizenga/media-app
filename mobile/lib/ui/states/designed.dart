import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/network/failures.dart';
import '../../l10n/gen/strings.dart';
import '../components/basics.dart';
import '../tokens/news_icon.dart';
import '../tokens/theme.dart';

enum Drawing {
  empty('M34 30h52a6 6 0 0 1 6 6v56l-32-18-32 18V36a6 6 0 0 1 6-6ZM46 46h28M46 56h18'),
  error(
    'M28 30h64a6 6 0 0 1 6 6v48a6 6 0 0 1-6 6H28a6 6 0 0 1-6-6V36a6 6 0 0 1 6-6ZM22 46h76M34 60h20M34 70h34M78 58l12 12M90 58 78 70',
  ),
  offline('M26 56a50 50 0 0 1 68 0M38 68a33 33 0 0 1 44 0M50 80a16 16 0 0 1 20 0M28 96 92 28');

  const Drawing(this.path);
  final String path;
}

/// The same drawings as the website: one sentence, one action.
class Designed extends StatelessWidget {
  const Designed({
    super.key,
    required this.drawing,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
    this.kind = ButtonKind.primary,
  });

  final Drawing drawing;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final ButtonKind kind;

  /// What went wrong, in the reader's words.
  static Widget failure(
    BuildContext context,
    Object error, {
    required VoidCallback retry,
    VoidCallback? home,
    VoidCallback? saved,
  }) {
    final s = Strings.of(context);
    return switch (Failure.from(error)) {
      OfflineFailure() => Designed(
        drawing: Drawing.offline,
        title: s.offlineTitle,
        body: s.offlineBody,
        action: saved == null ? s.retry : s.offlineAction,
        onAction: saved ?? retry,
        kind: saved == null ? ButtonKind.primary : ButtonKind.secondary,
      ),
      NotFoundFailure() => Designed(
        drawing: Drawing.empty,
        title: s.notFoundTitle,
        body: s.notFoundBody,
        action: home == null ? null : s.goHome,
        onAction: home,
      ),
      _ => Designed(
        drawing: Drawing.error,
        title: s.errorTitle,
        body: s.errorBody,
        action: s.retry,
        onAction: retry,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s8, vertical: NewsSpace.s12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
                  child: CustomPaint(painter: _DrawingPainter(drawing.path, c.textSecondary)),
                ),
              ),
              const SizedBox(height: NewsSpace.s6),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: context.type.headlineM.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(height: NewsSpace.s2),
              Text(
                body,
                textAlign: TextAlign.center,
                style: context.type.bodyM.copyWith(color: c.textSecondary),
              ),
              if (action != null && onAction != null) ...[
                const SizedBox(height: NewsSpace.s6),
                NewsButton(action!, onTap: onAction, kind: kind),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  const _DrawingPainter(this.path, this.color);

  final String path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    canvas.drawPath(
      parseSvgPath(path),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_DrawingPainter old) => old.path != path || old.color != color;
}
