import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

void main() {
  final vectors =
      jsonDecode(File('../spec/vectors.json').readAsStringSync()) as Map<String, dynamic>;

  test('the Dart port answers the shared vectors, to the last digit', () {
    expect(themeKeys, vectors['themes']);
    for (final c in (vectors['cases'] as List).cast<Map<String, dynamic>>()) {
      final got = [
        for (final theme in themeKeys)
          for (final scheme in ThemeScheme.values)
            derive(theme, scheme, c['color'] as String, c['dark'] as String)
                .values
                .map((v) => v.substring(1))
                .join(),
      ];
      expect(got, c['tokens'], reason: c['color'] as String);
    }
    for (final p in (vectors['paints'] as List).cast<Map<String, dynamic>>()) {
      final from = (p['from'] as List).map((v) => (v as num).toDouble()).toList();
      expect(paint((p['l'] as num).toDouble(), from[1], from[2], from[3]), p['hex']);
    }
  });

  test('the bundled default is Red Signature, derived', () {
    final light = derive(defaultTheme, ThemeScheme.light, defaultBrandColor);
    final dark = derive(defaultTheme, ThemeScheme.dark, defaultBrandColor);
    expect(defaultTheme, 'signature');
    expect(NewsColors.fromTokens(light).brand, NewsColors.light.brand);
    expect(NewsColors.fromTokens(dark).brandText, NewsColors.dark.brandText);
  });
}
