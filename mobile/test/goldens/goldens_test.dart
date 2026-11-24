@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/features/article/blocks.dart';
import 'package:news_app/features/home/home_screen.dart';
import 'package:news_app/ui/components/cards.dart';
import 'package:news_content/news_content.dart' hide TableRow;

import '../support/harness.dart';

/// Pictures of the app, with its real fonts. Linux only: CI and this container draw alike.
/// `flutter test --update-goldens --tags golden` after a change made on purpose.
void main() {
  setUpAll(loadFonts);
  final article = FakeApi.data('sw')['article'] as Map<String, dynamic>;
  final paths = {
    for (final l in ['sw', 'en']) l: (FakeApi.data(l)['article'] as Map)['path'] as String,
  };

  Future<void> golden(WidgetTester t, String name) async {
    await expectLater(find.byType(MaterialApp).first, matchesGoldenFile('images/$name.png'));
  }

  Future<void> visit(Phone p, String screen, String locale) async => switch (screen) {
    'home' => null,
    'article' => await p.push(paths[locale]!),
    'shorts' => await p.go('/video'),
    'explore' => await p.go('/search'),
    'saved' => await p.go('/saved'),
    'you' => await p.go('/profile'),
    'category' => await p.push(locale == 'sw' ? '/biashara' : '/en/business'),
    _ => throw ArgumentError(screen),
  };

  // Signature: every place, loaded and loading and failing, light and dark, both languages.
  for (final scheme in [SchemeChoice.light, SchemeChoice.dark]) {
    for (final locale in ['sw', 'en']) {
      final name = '${scheme.name}-$locale';
      for (final screen in ['home', 'article', 'shorts', 'explore', 'saved', 'you', 'category']) {
        testWidgets('$screen loaded $name', (t) async {
          final p = await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale);
          await visit(p, screen, locale);
          await golden(t, 'signature/$screen-loaded-$name');
        });
      }
      for (final screen in ['home', 'article', 'shorts', 'explore', 'category']) {
        testWidgets('$screen skeleton $name', (t) async {
          final p = await start(
            t,
            dpr: 1,
            photographs: false,
            scheme: scheme,
            locale: locale,
            api: FakeApi()..silent = true,
            settle: false,
          );
          await p.settle(3);
          await visit(p, screen, locale);
          await golden(t, 'signature/$screen-skeleton-$name');
        });
        testWidgets('$screen offline $name', (t) async {
          final p = await start(
            t,
            dpr: 1,
            photographs: false,
            scheme: scheme,
            locale: locale,
            api: FakeApi(offline: true),
          );
          await visit(p, screen, locale);
          await golden(t, 'signature/$screen-offline-$name');
        });
      }
      testWidgets('home error $name', (t) async {
        final api = FakeApi()..replies['/api/v1/content/home'] = 500;
        await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale, api: api);
        await golden(t, 'signature/home-error-$name');
      });
      testWidgets('category empty $name', (t) async {
        final full = FakeApi.data(locale)['category'] as Map<String, dynamic>;
        final api = FakeApi()
          ..replies['/api/v1/content/categories/${locale == 'sw' ? 'biashara' : 'business'}'] = {
            ...full,
            'results': <Object>[],
            'next_cursor': null,
          };
        final p = await start(
          t,
          dpr: 1,
          photographs: false,
          scheme: scheme,
          locale: locale,
          api: api,
        );
        await visit(p, 'category', locale);
        await golden(t, 'signature/category-empty-$name');
      });
      testWidgets('onboarding $name', (t) async {
        await start(
          t,
          dpr: 1,
          photographs: false,
          scheme: scheme,
          locale: locale,
          onboarded: false,
        );
        await golden(t, 'signature/welcome-$name');
      });
    }
    testWidgets('expanded ${scheme.name}', (t) async {
      final p = await start(t, dpr: 1, photographs: false, scheme: scheme, size: tablet);
      await golden(t, 'signature/home-expanded-${scheme.name}');
      await visit(p, 'article', 'sw');
      await golden(t, 'signature/article-expanded-${scheme.name}');
    });
    // The other two themes: the key screens.
    for (final theme in ['bold', 'quiet']) {
      for (final screen in ['home', 'article', 'shorts']) {
        testWidgets('$theme $screen ${scheme.name}', (t) async {
          final p = await start(
            t,
            dpr: 1,
            photographs: false,
            scheme: scheme,
            theme: ThemeChoice(key: theme, color: '#b5121b'),
          );
          await visit(p, screen, 'sw');
          await golden(t, '$theme/$screen-${scheme.name}');
        });
      }
    }
  }
  for (final screen in ['home', 'article', 'you', 'shorts']) {
    testWidgets('$screen at twice the text size', (t) async {
      final p = await start(t, dpr: 1, photographs: false, textScale: 2);
      await visit(p, screen, 'sw');
      await golden(t, 'signature/$screen-large-text');
    });
  }

  // Every content fixture, drawn whole.
  final fixtures =
      Directory('../support/docs/content-fixtures/valid')
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.contains('long-article'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in fixtures) {
    final name = file.uri.pathSegments.last.replaceAll('.json', '');
    for (final scheme in [SchemeChoice.light, SchemeChoice.dark]) {
      testWidgets('fixture $name ${scheme.name}', (t) async {
        final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final assets = <String, Map<String, dynamic>>{};
        final sample = article['image'] as Map<String, dynamic>;
        final clip =
            (((FakeApi.data('sw')['home'] as Map)['shorts'] as List).first as Map)['video']
                as Map<String, dynamic>;
        void collect(Object? node) {
          if (node is Map) {
            if (node['asset'] case final String id) {
              assets[id] = node['type'] == 'video' ? {...clip, 'id': id} : {...sample, 'id': id};
            }
            node.values.forEach(collect);
          } else if (node is List) {
            node.forEach(collect);
          }
        }

        collect(raw);
        final p = await start(
          t,
          dpr: 1,
          photographs: false,
          scheme: scheme,
          size: const Size(390, 3600),
        );
        final context = t.element(find.byType(HomeScreen));
        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            pageBuilder: (context, _, _) => Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                child: ArticleBody(
                  document: ContentDocument.read(raw),
                  data: BodyContext(assets: assets, links: const {}),
                ),
              ),
            ),
          ),
        );
        await p.settle(4);
        expect(t.takeException(), isNull);
        await golden(t, 'fixtures/$name-${scheme.name}');
      });
    }
  }
  testWidgets('a block from the future says so and nothing breaks', (t) async {
    final p = await start(t, dpr: 1, photographs: false);
    final context = t.element(find.byType(HomeScreen));
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => Scaffold(
          body: ArticleBody(
            document: ContentDocument.read({
              'version': 9,
              'blocks': [
                {'type': 'hologram', 'id': 'x'},
                42,
                {
                  'type': 'paragraph',
                  'id': 'y',
                  'content': [
                    {'type': 'text', 'text': 'Bado inasomeka'},
                  ],
                },
              ],
            }),
            data: BodyContext(assets: const {}, links: const {}),
          ),
        ),
      ),
    );
    await p.settle(2);
    expect(find.text('Sehemu hii inahitaji toleo jipya la programu.'), findsNWidgets(2));
    expect(find.textContaining('Bado inasomeka', findRichText: true), findsOneWidget);
  });

  // A skeleton is its component without data: the same shapes, within eight points.
  for (final screen in ['home', 'category', 'article']) {
    testWidgets('$screen: skeleton and story share their places', (t) async {
      Future<Map<String, Rect>> places({required bool loading}) async {
        final p = await start(
          t,
          dpr: 1,
          photographs: false,
          api: FakeApi()..silent = loading,
          settle: !loading,
        );
        if (loading) await p.settle(3);
        // Without the banner, which is absent until it is news.
        await visit(p, screen, 'sw');
        final found = <String, Rect>{};
        for (final (name, finder) in [
          ('cover', find.byType(CoverCard)),
          ('bar', find.byType(FeedBar)),
          ('row', find.byType(RowCard)),
          ('body', find.byType(ArticleBody)),
        ]) {
          if (finder.evaluate().isNotEmpty) found[name] = t.getRect(finder.first);
        }
        await p.stop();
        return found;
      }

      final empty = FakeApi.data('sw')['home'] as Map<String, dynamic>;
      final breaking = empty['breaking'];
      empty['breaking'] = <Object>[];
      final bones = await places(loading: true);
      final real = await places(loading: false);
      empty['breaking'] = breaking;
      for (final key in bones.keys.where(real.containsKey)) {
        expect(
          (bones[key]!.left - real[key]!.left).abs(),
          lessThanOrEqualTo(8),
          reason: '$key left',
        );
        expect(
          (bones[key]!.width - real[key]!.width).abs(),
          lessThanOrEqualTo(8),
          reason: '$key width',
        );
        // Headlines have the length their writers gave them: what is above them must not move.
        if (key == 'cover' || key == 'bar') {
          expect(
            (bones[key]!.top - real[key]!.top).abs(),
            lessThanOrEqualTo(8),
            reason: '$key top',
          );
        }
      }
    });
  }
}
