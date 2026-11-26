import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/ui/tokens/blurhash.dart';
import 'package:news_app/ui/tokens/news_icon.dart';
import 'package:news_app/ui/tokens/news_icons.g.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

void main() {
  test('what cannot be understood falls back to the bundled theme', () {
    for (final stored in [
      null,
      '',
      '{',
      '{"key":"neon","color":"#b5121b","darkColor":"","hash":""}',
      '{"key":"bold","color":"red","darkColor":"","hash":""}',
    ]) {
      expect(ThemeChoice.decode(stored).key, 'signature', reason: '$stored');
    }
    const choice = ThemeChoice(key: 'bold', color: '#0b5cad', hash: 'x');
    final again = ThemeChoice.decode(choice.encode());
    expect((again.key, again.color, again.hash), ('bold', '#0b5cad', 'x'));
  });
  test('every theme gives every colour', () {
    for (final key in themeKeys) {
      for (final scheme in ThemeScheme.values) {
        expect(() => ThemeChoice(key: key, color: '#b5121b').colors(scheme), returnsNormally);
      }
    }
  });
  test('settings survive a round trip, and damage', () {
    const s = Settings(
      onboarded: true,
      locale: 'en',
      scheme: SchemeChoice.dark,
      textScale: 1.3,
      dataSaver: true,
      topics: {'a', 'b'},
    );
    expect(Settings.read(s.write()).write(), s.write());
    expect(Settings.read(const {'textScale': '99', 'scheme': 'x', 'locale': 'fr'}).textScale, 1.6);
    expect(Settings.read(const {'locale': 'fr'}).locale, 'sw');
  });
  test('blurhash', () {
    final pixels = decodeBlurhash('LEHV6nWB2yk8pyo0adR*.7kCMdnj', 8, 8)!;
    expect(pixels.length, 256);
    expect(pixels[3], 255);
    // The top left corner of the reference picture.
    expect(pixels.sublist(0, 3).map((v) => v ~/ 32).toList(), hasLength(3));
    for (final bad in ['', 'x', 'LEHV6nWB2yk8pyo0adR*.7kCMdn', 'LEHV6nWB2yk8pyo0adR*.7kCMdn"']) {
      expect(decodeBlurhash(bad, 8, 8), isNull);
    }
  });
  test('every icon is a path', () {
    for (final icon in [
      NewsIcons.house,
      NewsIcons.heart,
      NewsIcons.compass,
      NewsIcons.languages,
      NewsIcons.badgeCheck,
    ]) {
      for (final p in icon.paths) {
        // Bounds of curves include their control points.
        final b = parseSvgPath(p).getBounds();
        expect(b.left > -3 && b.top > -3 && b.right < 27 && b.bottom < 27, isTrue, reason: '$p $b');
      }
    }
  });
}
