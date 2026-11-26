@Tags(['golden'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/app/router.dart';
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
      for (final screen in ['home', 'article', 'shorts', 'explore', 'category']) {
        testWidgets('$screen error $name', (t) async {
          final slug = paths[locale]!.split('/').last;
          final business = locale == 'sw' ? 'biashara' : 'business';
          final api = FakeApi();
          for (final path in switch (screen) {
            'article' => ['articles/$slug'],
            'shorts' => ['types/short'],
            'category' => ['categories/$business'],
            'explore' => ['navigation', 'home'],
            _ => ['home'],
          }) {
            api.replies['/api/v1/content/$path'] = 500;
          }
          final p = await start(
            t,
            dpr: 1,
            photographs: false,
            scheme: scheme,
            locale: locale,
            api: api,
          );
          await visit(p, screen, locale);
          await golden(t, 'signature/$screen-error-$name');
        });
      }
      testWidgets('saved, with and without the network $name', (t) async {
        final p = await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale);
        await p.push(paths[locale]!);
        await t.tap(find.bySemanticsLabel(locale == 'sw' ? 'Hifadhi' : 'Save').last);
        await p.settle();
        await t.pump(const Duration(seconds: 6));
        p.container.read(routerProvider).pop();
        await p.settle();
        await visit(p, 'saved', locale);
        await golden(t, 'signature/saved-kept-$name');
      });
      testWidgets('long videos $name', (t) async {
        final p = await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale);
        await visit(p, 'shorts', locale);
        await t.tap(find.text(locale == 'sw' ? 'Ndefu' : 'Videos'));
        await p.settle();
        await golden(t, 'signature/videos-loaded-$name');
      });
      testWidgets('live updates $name', (t) async {
        final p = await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale);
        await p.push((FakeApi.data(locale)['live'] as Map)['path'] as String);
        await golden(t, 'signature/live-loaded-$name');
      });
      testWidgets('a journalist $name', (t) async {
        final p = await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale);
        await p.push(locale == 'sw' ? '/author/mwandishi' : '/en/author/mwandishi');
        await golden(t, 'signature/author-loaded-$name');
      });
      for (final (state, config) in [
        (
          'update',
          {
            'versions': {
              for (final os in ['android', 'ios'])
                os: {'minimum': '9.0.0', 'recommended': '', 'store': 'https://store.test'},
            },
          },
        ),
        (
          'update-soft',
          {
            'versions': {
              for (final os in ['android', 'ios'])
                os: {'minimum': '', 'recommended': '9.0.0', 'store': 'https://store.test'},
            },
          },
        ),
        (
          'maintenance',
          {
            'maintenance': {'on': true, 'sw': 'Tunaboresha mfumo.', 'en': 'We are improving.'},
          },
        ),
      ]) {
        testWidgets('$state $name', (t) async {
          final api = FakeApi()..replies['/api/v1/app-config'] = FakeApi.config(config);
          await start(t, dpr: 1, photographs: false, scheme: scheme, locale: locale, api: api);
          await golden(t, 'signature/$state-$name');
        });
      }
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
        final p = await start(
          t,
          dpr: 1,
          photographs: false,
          scheme: scheme,
          locale: locale,
          onboarded: false,
        );
        await golden(t, 'signature/welcome-$name');
        await t.tap(find.text(locale == 'sw' ? 'Anza' : 'Get started'));
        await p.settle();
        await golden(t, 'signature/language-$name');
        await t.tap(find.text(locale == 'sw' ? 'Endelea' : 'Continue'));
        await p.settle();
        await golden(t, 'signature/topics-$name');
      });
    }
    for (final (width, size) in [('expanded', tablet), ('medium', const Size(768, 1024))]) {
      for (final screen in ['home', 'article', 'explore', 'saved', 'you', 'category', 'shorts']) {
        testWidgets('$screen $width ${scheme.name}', (t) async {
          final p = await start(t, dpr: 1, photographs: false, scheme: scheme, size: size);
          await visit(p, screen, 'sw');
          await golden(t, 'signature/$screen-$width-${scheme.name}');
        });
      }
      for (final screen in ['home', 'article', 'category']) {
        testWidgets('$screen $width skeleton ${scheme.name}', (t) async {
          final p = await start(
            t,
            dpr: 1,
            photographs: false,
            scheme: scheme,
            size: size,
            api: FakeApi()..silent = true,
            settle: false,
          );
          await p.settle(3);
          await visit(p, screen, 'sw');
          await golden(t, 'signature/$screen-$width-skeleton-${scheme.name}');
        });
      }
    }
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
      testWidgets('$theme welcome ${scheme.name}', (t) async {
        await start(
          t,
          dpr: 1,
          photographs: false,
          scheme: scheme,
          onboarded: false,
          theme: ThemeChoice(key: theme, color: '#b5121b'),
        );
        await golden(t, '$theme/welcome-${scheme.name}');
      });
    }
  }
  // Each platform's own shell, bars, sheets, dialogs and settings.
  for (final scheme in [SchemeChoice.light, SchemeChoice.dark]) {
    const platforms = TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});
    Future<void> native(WidgetTester t, String name) =>
        golden(t, 'native/${defaultTargetPlatform.name}-$name-${scheme.name}');
    Future<Phone> open(WidgetTester t) => start(t, dpr: 1, photographs: false, scheme: scheme);
    for (final screen in ['home', 'article', 'shorts', 'explore', 'saved', 'you', 'category']) {
      testWidgets('native $screen ${scheme.name}', variant: platforms, (t) async {
        final p = await open(t);
        await visit(p, screen, 'sw');
        await native(t, screen);
      });
    }
    testWidgets('native home scrolled ${scheme.name}', variant: platforms, (t) async {
      final p = await open(t);
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -320));
      await p.settle(2);
      await native(t, 'home-scrolled');
    });
    testWidgets('native choice ${scheme.name}', variant: platforms, (t) async {
      final p = await open(t);
      await p.go('/profile');
      await t.tap(find.text('Mwonekano'));
      await p.settle();
      await native(t, 'choice');
    });
    testWidgets('native dialog ${scheme.name}', variant: platforms, (t) async {
      final p = await open(t);
      await p.push(paths['sw']!);
      await p.go('/saved');
      await t.tap(find.text('Ulizosoma'));
      await p.settle();
      await t.tap(find.bySemanticsLabel('Futa historia'));
      await p.settle();
      await native(t, 'dialog');
    });
    testWidgets('native menu ${scheme.name}', variant: platforms, (t) async {
      final p = await open(t);
      await t.longPress(find.byType(CoverCard).first);
      await p.settle();
      await native(t, 'menu');
    });
  }
  // S1's two phones, in both languages.
  for (final locale in ['sw', 'en']) {
    for (final (name, size) in [('360x640', const Size(360, 640)), ('390x844', phone)]) {
      testWidgets('first screen $name $locale', (t) async {
        await start(t, dpr: 1, photographs: false, locale: locale, size: size);
        await golden(t, 'signature/first-screen-$name-$locale');
      });
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
  final fixtures = Directory(
    '../support/docs/content-fixtures/valid',
  ).listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
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
        if (name == 'long-article') {
          // Laid out whole; its picture is of its end, so that it stays a small file.
          final at = t.state<ScrollableState>(find.byType(Scrollable).last).position;
          at.jumpTo(at.maxScrollExtent);
          expect(at.pixels, greaterThan(10000));
          await p.settle(2);
        }
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
          ('bar', find.byType(TabBar)),
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
      final live = empty['live'];
      empty['live'] = <Object>[]; // with both: space_test
      final bones = await places(loading: true);
      final real = await places(loading: false);
      empty['breaking'] = breaking;
      empty['live'] = live;
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
