@Tags(['look'])
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/ui/components/cards.dart';

import '../support/harness.dart';

/// Both platforms, for the before and after gallery:
/// `flutter test --run-skipped --tags look test/screens/native_gallery_test.dart`
/// Names: `platform--scheme--screen.png` in build/gallery-native.
void main() {
  setUpAll(loadFonts);
  final out = Directory('build/gallery-native')..createSync(recursive: true);
  const both = TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});
  final data = FakeApi.data('sw');
  final article = (data['article'] as Map)['path'] as String;
  for (final scheme in [SchemeChoice.light, SchemeChoice.dark]) {
    Future<void> shot(WidgetTester t, String name) async {
      final png = await capture(t);
      final file = '${defaultTargetPlatform.name.toLowerCase()}--${scheme.name}--$name.png';
      await t.runAsync(() => File('${out.path}/$file').writeAsBytes(png));
    }

    Future<Phone> open(
      WidgetTester t, {
      Size size = phone,
      ThemeChoice? theme,
      String locale = 'sw',
    }) => start(t, scheme: scheme, size: size, theme: theme, locale: locale);
    final s = scheme.name;
    testWidgets('home $s', variant: both, (t) async {
      final p = await open(t);
      await shot(t, 'home');
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -330));
      await p.settle(3);
      await shot(t, 'home-scrolled');
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -700));
      await p.settle(3);
      await shot(t, 'home-feed');
      await t.tap(find.text('Habari mpya').first);
      await p.settle();
      await shot(t, 'home-latest');
    });
    testWidgets('small $s', variant: both, (t) async {
      await open(t, size: const Size(360, 640));
      await shot(t, 'home-small');
    });
    testWidgets('english $s', variant: both, (t) async {
      await open(t, locale: 'en');
      await shot(t, 'home-english');
    });
    testWidgets('article $s', variant: both, (t) async {
      final p = await open(t);
      await p.push(article);
      await shot(t, 'article');
      await t.drag(find.byType(CustomScrollView).last, const Offset(0, -520));
      await p.settle(3);
      await shot(t, 'article-reading');
    });
    testWidgets('places $s', variant: both, (t) async {
      final p = await open(t);
      await p.go('/video');
      await shot(t, 'shorts');
      await t.tap(find.text('Ndefu'));
      await p.settle();
      await shot(t, 'videos');
      await p.go('/search');
      await shot(t, 'explore');
      await p.go('/saved');
      await shot(t, 'saved');
      await p.go('/profile');
      await shot(t, 'you');
      await t.tap(find.text('Mwonekano'));
      await p.settle();
      await shot(t, 'choice');
    });
    testWidgets('lists $s', variant: both, (t) async {
      final p = await open(t);
      await p.push('/biashara');
      await shot(t, 'category');
      await p.push('/author/mwandishi');
      await shot(t, 'author');
    });
    testWidgets('menu $s', variant: both, (t) async {
      final p = await open(t);
      await t.longPress(find.byType(CoverCard).first);
      await p.settle();
      await shot(t, 'menu');
    });
    for (final key in ['bold', 'quiet']) {
      testWidgets('$key $s', variant: both, (t) async {
        final p = await open(
          t,
          theme: ThemeChoice(key: key, color: '#b5121b'),
        );
        await shot(t, 'home-$key');
        await p.push(article);
        await shot(t, 'article-$key');
      });
    }
    testWidgets('wide $s', (t) async {
      final p = await open(t, size: tablet);
      await shot(t, 'tablet-home');
      await p.push(article);
      await shot(t, 'tablet-article');
    });
    testWidgets('medium $s', (t) async {
      await open(t, size: const Size(768, 1024));
      await shot(t, 'medium-home');
    });
  }
}
