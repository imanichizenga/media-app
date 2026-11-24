// Brand colour → every token of every theme. Port of src/theme.ts, judged by spec/vectors.json; the rules are
// spec/derivation.md.
import 'dart:convert';
import 'dart:math' as math;

import 'theme_spec.g.dart';

typedef Tokens = Map<String, String>;

enum ThemeScheme { light, dark }

/// Lightness, chroma and the direction of the hue.
class Oklch {
  const Oklch(this.l, this.c, this.x, this.y);

  final double l;
  final double c;
  final double x;
  final double y;
}

final Map<String, dynamic> themeSpec = jsonDecode(themeSpecJson) as Map<String, dynamic>;
final Map<String, dynamic> _themes = themeSpec['themes'] as Map<String, dynamic>;
final List<String> themeKeys = List.unmodifiable(_themes.keys);
final String defaultTheme = themeSpec['default'] as String;
final String defaultBrandColor = themeSpec['color'] as String;

double _decode(double c) =>
    c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
double _encode(double c) =>
    c <= 0.0031308 ? 12.92 * c : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;
double _cbrt(double v) => math.pow(v, 1 / 3).toDouble();

List<double> _channels(String hex) => [
  for (final i in const [1, 3, 5]) _decode(int.parse(hex.substring(i, i + 2), radix: 16) / 255),
];

double _luminance(String hex) {
  final [r, g, b] = _channels(hex);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrast(String a, String b) {
  final x = _luminance(a);
  final y = _luminance(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

Oklch oklch(String hex) {
  final [r, g, b] = _channels(hex);
  final p = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final q = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  final l = 0.2104542553 * p + 0.793617785 * q - 0.0040720468 * s;
  final A = 1.9779984951 * p - 2.428592205 * q + 0.4505937099 * s;
  final B = 0.0259040371 * p + 0.7827717662 * q - 0.808675766 * s;
  final c = math.sqrt(A * A + B * B);
  return c < 0.0005 ? Oklch(l, 0, 0, 0) : Oklch(l, c, A / c, B / c);
}

List<double> _linear(double l, double c, double x, double y) {
  final a = c * x;
  final b = c * y;
  final p = l + 0.3963377774 * a + 0.2158037573 * b;
  final q = l - 0.1055613458 * a - 0.0638541728 * b;
  final s = l - 0.0894841775 * a - 1.291485548 * b;
  final p3 = p * p * p;
  final q3 = q * q * q;
  final s3 = s * s * s;
  return [
    4.0767416621 * p3 - 3.3077115913 * q3 + 0.2309699292 * s3,
    -1.2684380046 * p3 + 2.6097574011 * q3 - 0.3413193965 * s3,
    -0.0041960863 * p3 - 0.7034186147 * q3 + 1.707614701 * s3,
  ];
}

bool _inside(List<double> rgb) => rgb.every((v) => v >= -0.0001 && v <= 1.0001);

/// The nearest colour a screen can show: lightness and hue are kept, chroma gives way.
String paint(double l, double c, double x, double y) {
  var rgb = _linear(l, c, x, y);
  if (!_inside(rgb)) {
    var low = 0.0;
    var high = c;
    for (var i = 0; i < 20; i++) {
      final mid = (low + high) / 2;
      if (_inside(_linear(l, mid, x, y))) {
        low = mid;
      } else {
        high = mid;
      }
    }
    rgb = _linear(l, low, x, y);
  }
  final hex = rgb
      .map((v) => (_encode(v.clamp(0.0, 1.0)) * 255 + 0.5).floor())
      .map((v) => v.toRadixString(16).padLeft(2, '0'));
  return '#${hex.join()}';
}

Tokens derive(String theme, ThemeScheme scheme, String color, [String darkColor = '']) {
  final source = (_themes[theme] as Map<String, dynamic>)[scheme.name] as Map<String, dynamic>;
  final override = scheme == ThemeScheme.dark && darkColor.isNotEmpty;
  final base = (override ? darkColor : color).toLowerCase();
  final o = oklch(base);
  final out = <String, String>{...(source['neutral'] as Map<String, dynamic>).cast<String, String>()};
  String value(String name) => name.startsWith('#') ? name : out[name]!;
  String walk(double start, double step, double c, List<String> grounds, double min) {
    for (var i = 0; ; i++) {
      final l = start + step * i;
      final hex = paint(l, c, o.x, o.y);
      if (l >= 1 || grounds.every((g) => contrast(hex, g) >= min)) return hex;
    }
  }

  for (final MapEntry(key: name, value: rule) in (source['brand'] as Map<String, dynamic>).entries) {
    if (rule is String) {
      out[name] = rule.startsWith('@') ? value(rule.substring(1)) : rule;
      continue;
    }
    final [op, ...rest] = rule as List<dynamic>;
    List<String> grounds() => [for (final r in rest) value(r as String)];
    out[name] = switch (op) {
      'exact' => base,
      'fill' => walk(0.3, 0.0025, o.c * 0.92, grounds(), 3),
      'soften' => override ? base : walk(0.64, 0.005, math.min(o.c * 0.9, 0.17), grounds(), 4.5),
      'strong' => () {
        final f = oklch(value(rest[0] as String));
        return paint(math.max(0, f.l - 0.055), f.c, f.x, f.y);
      }(),
      'tint' => paint(
        (rest[0] as num).toDouble(),
        math.min(o.c, (rest[1] as num).toDouble()),
        o.x,
        o.y,
      ),
      _ => throw FormatException('Unknown rule $op'),
    };
  }
  return out;
}
