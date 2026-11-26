@Tags(['look'])
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/app/router.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/features/article/photo_viewer.dart';

import '../support/harness.dart';

/// Draws the gallery into build/gallery: `flutter test --run-skipped --tags look test/screens/gallery_test.dart`.
/// Names: `theme--scheme--locale--screen.png`
void main() {
  setUpAll(loadFonts);
  final out = Directory('build/gallery')..createSync(recursive: true);
  final themes = {
    for (final key in ['signature', 'bold', 'quiet']) key: ThemeChoice(key: key, color: '#b5121b'),
  };
  for (final MapEntry(key: theme, value: choice) in themes.entries) {
    for (final scheme in [SchemeChoice.light, SchemeChoice.dark]) {
      for (final locale in theme == 'signature' ? ['sw', 'en'] : ['sw']) {
        final full = theme == 'signature' && locale == 'sw';
        final t0 = '$theme--${scheme.name}--$locale';
        Future<void> shot(WidgetTester t, String name) async {
          final png = await capture(t);
          await t.runAsync(() => File('${out.path}/$t0--$name.png').writeAsBytes(png));
        }

        Future<Phone> open(
          WidgetTester t, {
          FakeApi? api,
          bool onboarded = true,
          Size size = phone,
          bool settle = true,
        }) => start(
          t,
          theme: choice,
          scheme: scheme,
          locale: locale,
          api: api,
          onboarded: onboarded,
          size: size,
          settle: settle,
        );
        final data = FakeApi.data(locale);
        final article = (data['article'] as Map)['path'] as String;

        testWidgets('$t0 home', (t) async {
          final p = await open(t);
          await shot(t, '01-home');
          if (!full) return;
          for (final (i, name) in ['02-home-stories', '03-home-feed', '04-home-video'].indexed) {
            await t.drag(find.byType(Scrollable).first, Offset(0, i == 2 ? -900 : -640));
            await p.settle(3);
            await shot(t, name);
          }
        });
        testWidgets('$t0 article', (t) async {
          final p = await open(t);
          await p.push(article);
          await shot(t, '05-article');
          if (!full) return;
          for (final name in ['06-article-body', '07-article-quote']) {
            await t.drag(find.byType(Scrollable).last, const Offset(0, -720));
            await p.settle(3);
            await shot(t, name);
          }
          await t.drag(find.byType(Scrollable).last, const Offset(0, -9000));
          await p.settle(4);
          await t.drag(find.byType(Scrollable).last, const Offset(0, 300));
          await p.settle(4);
          await shot(t, '08-article-next');
        });
        testWidgets('$t0 live', (t) async {
          final p = await open(t);
          await p.push((data['live'] as Map)['path'] as String);
          await t.drag(find.byType(Scrollable).last, const Offset(0, -330));
          await p.settle(3);
          await shot(t, '09-live-blog');
        });
        testWidgets('$t0 places', (t) async {
          final p = await open(t);
          await p.go('/video');
          await shot(t, '10-shorts');
          if (theme != 'signature') return;
          await p.go('/search');
          await shot(t, '12-explore');
          await p.go('/profile');
          await shot(t, '15-you');
          await p.push('/biashara');
          await shot(t, '13-category');
          if (!full) return;
          await p.push('/author/mwandishi');
          await shot(t, '14-author');
        });
        if (full) {
          testWidgets('$t0 videos', (t) async {
            final p = await open(t);
            await p.go('/video');
            await t.tap(find.text('Ndefu'));
            await p.settle();
            await shot(t, '11-videos');
          });
          testWidgets('$t0 saved', (t) async {
            final p = await open(t);
            await p.go('/saved');
            await shot(t, '18-saved-empty');
            await p.push(article);
            await t.tap(find.bySemanticsLabel('Hifadhi').last);
            await p.settle();
            await t.pump(const Duration(seconds: 6));
            await p.settle();
            p.container.read(routerProvider).pop();
            await p.settle();
            await shot(t, '17-saved');
          });
          testWidgets('$t0 photo', (t) async {
            final p = await open(t);
            await p.push(article);
            await t.drag(find.byType(Scrollable).last, const Offset(0, -720));
            await p.settle(3);
            final pictures = find.bySemanticsLabel(
              RegExp('mfano|Mchoro|picha', caseSensitive: false),
            );
            if (pictures.evaluate().isNotEmpty) {
              await t.tap(pictures.first, warnIfMissed: false);
              await p.settle(4);
            }
            if (find.byType(PhotoViewer).evaluate().isNotEmpty) await shot(t, '16-photo');
          });
          testWidgets('$t0 states', (t) async {
            await open(t, api: FakeApi(offline: true));
            await shot(t, '22-offline');
          });
          testWidgets('$t0 error', (t) async {
            final api = FakeApi()..replies['/api/v1/content/home'] = 500;
            await open(t, api: api);
            await shot(t, '23-error');
          });
          testWidgets('$t0 update', (t) async {
            final api = FakeApi()
              ..replies['/api/v1/app-config'] = FakeApi.config({
                'versions': {
                  for (final os in ['android', 'ios'])
                    os: {'minimum': '9.0.0', 'recommended': '', 'store': 'https://store.test/app'},
                },
              });
            await open(t, api: api);
            await shot(t, '24-update');
          });
          testWidgets('$t0 skeletons', (t) async {
            final p = await open(t, api: FakeApi()..silent = true, settle: false);
            await p.settle();
            await shot(t, '25-home-skeleton');
            await p.push(article);
            await shot(t, '26-article-skeleton');
          });
          testWidgets('$t0 tablet', (t) async {
            final p = await open(t, size: tablet);
            await shot(t, '30-tablet-home');
            await p.push(article);
            await shot(t, '31-tablet-article');
          });
          testWidgets('$t0 medium', (t) async {
            await open(t, size: const Size(768, 1024));
            await shot(t, '32-medium-home');
          });
        }
        testWidgets('$t0 onboarding', (t) async {
          final p = await open(t, onboarded: false);
          await shot(t, '19-welcome');
          if (!full) return;
          await t.tap(find.text('Anza'));
          await p.settle();
          await shot(t, '20-language');
          await t.tap(find.text('Endelea'));
          await p.settle();
          await t.tap(find.text('Michezo'));
          await t.tap(find.text('Afya'));
          await p.settle();
          await shot(t, '21-topics');
        });
      }
    }
  }
}
