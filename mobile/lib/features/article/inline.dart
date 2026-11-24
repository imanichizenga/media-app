import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_content/news_content.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/links.dart';
import '../../core/config/env.dart';
import '../../ui/tokens/theme.dart';

/// Our own addresses open in the app, the rest in the browser. Nothing but https, mail and telephone.
Future<void> follow(BuildContext context, String href) async {
  final uri = Uri.tryParse(href);
  if (uri == null) return;
  final ours = !uri.hasScheme && href.startsWith('/') && !href.startsWith('//') ||
      uri.scheme == 'https' && uri.host == Env.webHost;
  if (ours && parsePlace(uri.path) is! OutsidePlace) {
    await context.push(uri.path);
    return;
  }
  final target = ours && !uri.hasScheme ? Uri.https(Env.webHost, uri.path) : uri;
  if (const {'https', 'mailto', 'tel'}.contains(target.scheme)) {
    await launchUrl(target, mode: LaunchMode.externalApplication);
  }
}

String plain(List<Inline>? content) => (content ?? const []).map((n) => switch (n) {
  TextNode(:final text) => text,
  HardBreak() => '\n',
  UnknownInline() => '',
}).join();

/// Text with its marks. What this version does not know is shown as plain text.
class InlineText extends StatefulWidget {
  const InlineText(this.content, {super.key, required this.style, this.align});

  final List<Inline> content;
  final TextStyle style;
  final TextAlign? align;

  @override
  State<InlineText> createState() => _InlineTextState();
}

class _InlineTextState extends State<InlineText> {
  final _taps = <TapGestureRecognizer>[];

  void _clear() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  InlineSpan _span(Inline node) {
    if (node is HardBreak) return const TextSpan(text: '\n');
    if (node is! TextNode) return const TextSpan();
    final c = context.colors;
    var style = const TextStyle();
    final lines = <TextDecoration>[];
    TapGestureRecognizer? tap;
    for (final mark in node.marks ?? const <Mark>[]) {
      switch (mark) {
        case SimpleMark(type: SimpleMarkType.bold):
          style = style.copyWith(
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
          );
        case SimpleMark(type: SimpleMarkType.italic):
          style = style.copyWith(fontStyle: FontStyle.italic);
        case SimpleMark(type: SimpleMarkType.underline):
          lines.add(TextDecoration.underline);
        case SimpleMark(type: SimpleMarkType.strike):
          lines.add(TextDecoration.lineThrough);
        case SimpleMark(type: SimpleMarkType.code):
          style = style.copyWith(
            fontFamily: 'monospace',
            fontSize: (widget.style.fontSize ?? 16) * 0.9,
            backgroundColor: c.surfaceSunken,
          );
        case SimpleMark(type: SimpleMarkType.superscript):
          style = style.copyWith(fontFeatures: const [FontFeature.superscripts()]);
        case SimpleMark(type: SimpleMarkType.subscript):
          style = style.copyWith(fontFeatures: const [FontFeature.subscripts()]);
        case LinkMark(:final href):
          tap = TapGestureRecognizer()..onTap = () => follow(context, href);
          _taps.add(tap);
          lines.add(TextDecoration.underline);
          style = style.copyWith(color: c.link, decorationColor: c.link, decorationThickness: 1);
        case SimpleMark() || UnknownMark():
      }
    }
    if (lines.isNotEmpty) style = style.copyWith(decoration: TextDecoration.combine(lines));
    return TextSpan(text: node.text, style: style, recognizer: tap);
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    return Text.rich(
      TextSpan(children: widget.content.map(_span).toList()),
      style: widget.style,
      textAlign: widget.align,
    );
  }
}
