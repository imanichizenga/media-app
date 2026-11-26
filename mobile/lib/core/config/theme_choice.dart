import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:news_api_client/news_api_client.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

/// The published theme as this installation knows it. Red Signature is bundled, so the first launch and launches
/// without a connection look right.
@immutable
class ThemeChoice {
  const ThemeChoice({required this.key, required this.color, this.darkColor = '', this.hash = ''});

  factory ThemeChoice.bundled() => ThemeChoice(key: defaultTheme, color: defaultBrandColor);

  factory ThemeChoice.of(SiteTheme t) =>
      ThemeChoice(key: t.key.value, color: t.color, darkColor: t.darkColor, hash: t.hash);

  /// A theme this version does not know, or a damaged value, falls back to the bundled one.
  static ThemeChoice decode(String? stored) {
    try {
      final m = jsonDecode(stored!) as Map<String, dynamic>;
      final choice = ThemeChoice(
        key: m['key'] as String,
        color: m['color'] as String,
        darkColor: m['darkColor'] as String,
        hash: m['hash'] as String,
      );
      if (!themeKeys.contains(choice.key)) return ThemeChoice.bundled();
      choice.tokens(ThemeScheme.dark);
      return choice;
    } on Object {
      return ThemeChoice.bundled();
    }
  }

  final String key;
  final String color;
  final String darkColor;
  final String hash;

  String encode() => jsonEncode({'key': key, 'color': color, 'darkColor': darkColor, 'hash': hash});

  Tokens tokens(ThemeScheme scheme) => derive(key, scheme, color, darkColor);
  NewsColors colors(ThemeScheme scheme) => NewsColors.fromTokens(tokens(scheme));
}
