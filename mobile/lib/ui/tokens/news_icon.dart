import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A Lucide icon as path data on a 24-pixel grid: the same drawings as the website, with a filled form.
@immutable
class NewsIconData {
  const NewsIconData(this.paths);

  final List<String> paths;
}

class NewsIcon extends StatelessWidget {
  const NewsIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color,
    this.stroke = 1.75,
    this.filled = false,
  });

  final NewsIconData icon;
  final double size;
  final Color? color;
  final double stroke;
  final bool filled;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(
        icon,
        color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color!,
        stroke,
        filled,
      ),
    ),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.icon, this.color, this.stroke, this.filled);

  final NewsIconData icon;
  final Color color;
  final double stroke;
  final bool filled;

  static final _parsed = <String, ui.Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    for (final data in icon.paths) {
      final path = _parsed[data] ??= parseSvgPath(data);
      if (filled) canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color || old.stroke != stroke || old.filled != filled;
}

final _token = RegExp(r'[a-zA-Z]|[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

/// SVG path data → a path. Arc flags may be written without separators, as Lucide does.
ui.Path parseSvgPath(String data) {
  final path = ui.Path();
  var i = 0;
  final source = data;
  double number() {
    final m = _token.matchAsPrefix(source, _skip(source, i))!;
    i = m.end;
    return double.parse(m[0]!);
  }

  bool flag() {
    i = _skip(source, i);
    return source[i++] == '1';
  }

  bool more() {
    final at = _skip(source, i);
    return at < source.length && !RegExp('[a-zA-Z]').hasMatch(source[at]);
  }

  var (x, y, sx, sy) = (0.0, 0.0, 0.0, 0.0);
  var (cx, cy) = (0.0, 0.0);
  var last = '';
  while (_skip(source, i) < source.length) {
    i = _skip(source, i);
    final command = source[i++];
    final rel = command == command.toLowerCase();
    var first = true;
    final op = command.toUpperCase();
    if (op == 'Z') {
      path.close();
      (x, y) = (sx, sy);
      last = op;
      continue;
    }
    do {
      final (ox, oy) = rel ? (x, y) : (0.0, 0.0);
      switch (op) {
        case 'M':
          (x, y) = (ox + number(), oy + number());
          if (first) {
            path.moveTo(x, y);
            (sx, sy) = (x, y);
          } else {
            path.lineTo(x, y);
          }
        case 'L':
          (x, y) = (ox + number(), oy + number());
          path.lineTo(x, y);
        case 'H':
          x = ox + number();
          path.lineTo(x, y);
        case 'V':
          y = oy + number();
          path.lineTo(x, y);
        case 'C' || 'S':
          double x1, y1;
          if (op == 'C') {
            (x1, y1) = (ox + number(), oy + number());
          } else {
            (x1, y1) = last == 'C' || last == 'S' ? (2 * x - cx, 2 * y - cy) : (x, y);
          }
          (cx, cy) = (ox + number(), oy + number());
          (x, y) = (ox + number(), oy + number());
          path.cubicTo(x1, y1, cx, cy, x, y);
        case 'Q' || 'T':
          if (op == 'Q') {
            (cx, cy) = (ox + number(), oy + number());
          } else {
            (cx, cy) = last == 'Q' || last == 'T' ? (2 * x - cx, 2 * y - cy) : (x, y);
          }
          (x, y) = (ox + number(), oy + number());
          path.quadraticBezierTo(cx, cy, x, y);
        case 'A':
          final (rx, ry, turn) = (number(), number(), number());
          final (large, sweep) = (flag(), flag());
          (x, y) = (ox + number(), oy + number());
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: turn,
            largeArc: large,
            clockwise: sweep,
          );
        default:
          throw FormatException('Unknown path command', data, i);
      }
      last = op;
      first = false;
    } while (more());
  }
  return path;
}

int _skip(String s, int at) {
  var i = at;
  while (i < s.length && (s[i] == ' ' || s[i] == ',' || s[i] == '\n')) {
    i++;
  }
  return i;
}
