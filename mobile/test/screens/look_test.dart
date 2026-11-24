@Tags(['look'])
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/core/storage/prefs.dart';

import 'package:news_app/app/router.dart';

import '../support/harness.dart';

/// Not a check: draws the screens into build/look, to be looked at. `flutter test --tags look`.
void main() {
  setUpAll(loadFonts);
  final out = Directory('build/look')..createSync(recursive: true);
  Future<void> shot(WidgetTester t, String name) async {
    final png = await capture(t);
    await t.runAsync(() => File('${out.path}/$name.png').writeAsBytes(png));
  }

  testWidgets('home', (t) async {
    final p = await start(t);
    await shot(t, 'home');
    for (var i = 1; i < 5; i++) {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await p.settle(3);
      await shot(t, 'home-$i');
    }
  });
  testWidgets('dark', (t) async {
    await start(t, scheme: SchemeChoice.dark);
    await shot(t, 'home-dark');
  });
  final article = FakeApi.data('sw')['article'] as Map<String, dynamic>;
  testWidgets('article', (t) async {
    final p = await start(t);
    await p.push(article['path'] as String);
    await shot(t, 'article');
    for (var i = 1; i < 6; i++) {
      await t.drag(find.byType(Scrollable).last, const Offset(0, -720));
      await p.settle(2);
      await shot(t, 'article-$i');
    }
  });
  testWidgets('article dark', (t) async {
    final p = await start(t, scheme: SchemeChoice.dark);
    await p.push(article['path'] as String);
    await shot(t, 'article-dark');
  });
  testWidgets('live', (t) async {
    final p = await start(t);
    final live = FakeApi.data('sw')['live'] as Map<String, dynamic>;
    await p.push(live['path'] as String);
    await t.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await p.settle(2);
    await shot(t, 'live');
  });
  testWidgets('tabs', (t) async {
    final p = await start(t);
    await p.go('/video');
    await shot(t, 'shorts');
    await t.tap(find.text('Ndefu'));
    await p.settle();
    await shot(t, 'videos');
    await p.go('/search');
    await shot(t, 'explore');
    await p.go('/saved');
    await shot(t, 'saved-empty');
    await p.go('/profile');
    await shot(t, 'you');
    await t.drag(find.byType(Scrollable).last, const Offset(0, -700));
    await p.settle(2);
    await shot(t, 'you-2');
    await p.push('/biashara');
    await shot(t, 'category');
    await p.push('/author/lilian');
    await shot(t, 'author');
  });
  testWidgets('saved', (t) async {
    final p = await start(t);
    await p.push(article['path'] as String);
    await t.tap(find.bySemanticsLabel('Hifadhi').last);
    await p.settle();
    await shot(t, 'article-saved');
    p.container.read(routerProvider).pop();
    await p.go('/saved');
    await shot(t, 'saved');
    await t.tap(find.text('Ulizosoma'));
    await p.settle();
    await shot(t, 'history');
  });
  testWidgets('onboarding', (t) async {
    final p = await start(t, onboarded: false);
    await shot(t, 'welcome');
    await t.tap(find.text('Anza'));
    await p.settle();
    await shot(t, 'language');
    await t.tap(find.text('Endelea'));
    await p.settle();
    await t.tap(find.text('Michezo'));
    await t.tap(find.text('Afya'));
    await p.settle();
    await shot(t, 'topics');
  });
  testWidgets('states', (t) async {
    await start(t, api: FakeApi(offline: true));
    await shot(t, 'offline');
  });
  testWidgets('skeleton', (t) async {
    final p = await start(t, api: FakeApi()..silent = true, settle: false);
    await p.settle();
    await shot(t, 'skeleton');
  });
  testWidgets('tablet', (t) async {
    final p = await start(t, size: tablet);
    await shot(t, 'tablet-home');
    await p.push(article['path'] as String);
    await shot(t, 'tablet-article');
  });
  testWidgets('tablet medium', (t) async {
    await start(t, size: const Size(768, 1024));
    await shot(t, 'medium-home');
  });
}
