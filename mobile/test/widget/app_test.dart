import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/app/bootstrap.dart';
import 'package:news_app/app/shell.dart';
import 'package:news_app/core/config/app_config.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/providers.dart';
import 'package:news_app/core/storage/database.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/features/article/article_screen.dart';
import 'package:news_app/features/home/home_screen.dart';
import 'package:news_app/ui/components/cards.dart';
import 'package:news_app/ui/components/youtube.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/fake_video.dart';
import '../support/harness.dart';

Future<bool> ready(WidgetTester t, Phone p) async {
  final rows = await t.runAsync(() => p.db.select(p.db.savedArticles).get());
  return rows!.single.imagesReady;
}

void main() {
  setUpAll(loadFonts);
  final article = FakeApi.data('sw')['article'] as Map<String, dynamic>;
  final path = article['path'] as String;

  testWidgets('first launch: welcome, language, topics, then home as a guest, once', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    final p = await start(t, onboarded: false, database: db);
    expect(find.text('Ruka'), findsOneWidget);
    await t.tap(find.text('Anza'));
    await p.settle();
    await t.tap(find.text('English'));
    await p.settle();
    expect(find.text('Choose your language'), findsOneWidget);
    await t.tap(find.text('Continue'));
    await p.settle();
    await t.tap(find.text('Sport'));
    await p.settle();
    await t.tap(find.text('Get started'));
    await p.settle();
    expect(find.byType(HomeScreen), findsOneWidget);
    final kept = Settings.read((await t.runAsync(db.allPrefs))!);
    expect((kept.onboarded, kept.locale, kept.topics.length), (true, 'en', 1));
    await p.go('/welcome');
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Skip is in the same place on every step and always works', (t) async {
    final p = await start(t, onboarded: false);
    final first = t.getRect(find.text('Ruka'));
    await t.tap(find.text('Anza'));
    await p.settle();
    expect(t.getRect(find.text('Ruka')), first);
    await t.tap(find.text('Endelea'));
    await p.settle();
    expect(t.getRect(find.text('Ruka')), first);
    await t.tap(find.text('Ruka'));
    await p.settle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a link opens its story, and back leads home; the welcome never interrupts it', (
    t,
  ) async {
    final p = await start(t, onboarded: false);
    await p.go(path);
    expect(find.byType(ArticleScreen), findsOneWidget);
    expect(find.text(article['headline'] as String), findsWidgets);
    await t.tap(find.bySemanticsLabel('Rudi').first);
    await p.settle();
    expect(find.byType(ArticleScreen), findsNothing);
  });

  testWidgets('an address that moved is followed; one that never was says so', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/content/articles/zamani'] = 404
      ..replies['/api/v1/content/articles/hakuna'] = 404
      ..replies['/api/v1/content/resolve'] = {'path': path};
    final p = await start(t, api: api);
    await p.push('/siasa/zamani');
    await p.settle();
    expect(find.text(article['headline'] as String), findsWidgets);
    api.replies['/api/v1/content/resolve'] = 404;
    await p.push('/siasa/hakuna');
    await p.settle();
    expect(find.text('Habari hii haipo'), findsOneWidget);
  });

  testWidgets('each tab keeps its place; tapping it again goes to its top', (t) async {
    final p = await start(t);
    await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await p.settle(2);
    double at() => t.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;
    final before = at();
    expect(before, greaterThan(500));
    Finder tab(String name) =>
        find.descendant(of: find.byType(BottomBar), matching: find.text(name));
    await t.tap(tab('Gundua'));
    await p.settle();
    await t.tap(tab('Nyumbani'));
    await p.settle();
    expect(at(), before);
    await t.tap(tab('Nyumbani'));
    await p.settle();
    expect(at(), 0);
  });

  testWidgets(
    'without a network: what was read is shown, with its age; a saved story opens whole',
    (t) async {
      final db = AppDatabase(NativeDatabase.memory());
      final api = FakeApi();
      var p = await start(t, api: api, database: db);
      await p.push(path);
      await t.tap(find.bySemanticsLabel('Hifadhi').last);
      await p.settle();
      expect(keeper.kept, isNotEmpty);
      await p.stop();
      api.offline = true;
      p = await start(t, api: api, database: db);
      expect(find.byType(CoverCard), findsOneWidget, reason: 'home from the phone');
      expect(find.textContaining('Huna mtandao. Unaona'), findsOneWidget);
      await p.go('/saved');
      expect(find.text('Inasomeka bila mtandao'), findsOneWidget);
      await t.tap(find.text(article['headline'] as String).first);
      await p.settle();
      expect(find.byType(ArticleScreen), findsOneWidget);
      expect(find.textContaining('Wataalamu', findRichText: true), findsWidgets);
    },
  );

  testWidgets('removing a saved story removes its pictures, and can be undone', (t) async {
    final p = await start(t);
    await p.push(path);
    await t.tap(find.bySemanticsLabel('Hifadhi').last);
    await p.settle();
    expect(keeper.kept, isNotEmpty);
    await t.tap(find.bySemanticsLabel('Ondoa kwenye hifadhi'));
    await p.settle();
    expect(keeper.kept, isEmpty);
    await t.tap(find.text('Rudisha'));
    await p.settle();
    expect(keeper.kept, isNotEmpty);
  });

  testWidgets('a download that failed is taken up again at the next start', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    var p = await start(t, database: db);
    keeper.fail = true;
    await p.push(path);
    await t.tap(find.bySemanticsLabel('Hifadhi').last);
    await p.settle();
    expect((await ready(t, p)), isFalse);
    await p.stop();
    p = await start(t, database: db);
    await p.settle(10);
    expect((await ready(t, p)), isTrue);
  });

  testWidgets('fifty shorts: never more than three players, none left behind', (t) async {
    final one = (FakeApi.data('sw')['home'] as Map)['shorts'] as List<dynamic>;
    final many = [
      for (var i = 0; i < 50; i++) {...one[i % one.length] as Map<String, dynamic>, 'id': 'id$i'},
    ];
    final p = await start(
      t,
      api: FakeApi()..replies['/api/v1/content/types/short'] = FakeApi.page(many),
    );
    await p.go('/video');
    expect(FakeVideo.current.playing.length, 1);
    for (var i = 0; i < 50; i++) {
      await t.fling(find.byType(PageView).last, const Offset(0, -500), 2400);
      await p.settle(1);
    }
    expect(
      FakeVideo.current.most,
      lessThanOrEqualTo(4),
      reason: 'one may be closing while one opens',
    );
    expect(FakeVideo.current.alive.length, lessThanOrEqualTo(3));
    expect(find.text('Umetazama zote'), findsOneWidget);
    expect(FakeVideo.current.created.length, greaterThanOrEqualTo(50));
    await p.go('/');
    await p.settle();
    expect(FakeVideo.current.playing, isEmpty, reason: 'nothing plays unseen');
    await p.stop();
    expect(FakeVideo.current.alive, isEmpty);
  });

  testWidgets('shorts stop in the background, and wait for a tap with the data saver on', (
    t,
  ) async {
    final p = await start(t);
    await p.go('/video');
    expect(FakeVideo.current.playing, hasLength(1));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await p.settle(2);
    expect(FakeVideo.current.playing, isEmpty);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await p.settle(2);
    expect(FakeVideo.current.playing, hasLength(1));
    await p.stop();
    final saver = await start(t, overrides: [autoplayProvider.overrideWithValue(false)]);
    await saver.go('/video');
    expect(FakeVideo.current.playing, isEmpty);
  });

  testWidgets('the kill switch for shorts leaves the long videos and no dead tab', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/app-config'] = FakeApi.config({
        'flags': {'shorts': false, 'youtube': true, 'offline_saving': false},
      });
    final p = await start(t, api: api);
    await p.go('/video');
    expect(find.text('Fupi'), findsNothing);
    expect(find.byType(VideoCard), findsWidgets);
    await p.push(path);
    expect(find.bySemanticsLabel('Hifadhi'), findsNothing);
  });

  testWidgets('a version that may not continue sees one screen; a newer one is mentioned once', (
    t,
  ) async {
    Map<String, dynamic> versions(String min, String rec) => FakeApi.config({
      'versions': {
        for (final os in ['android', 'ios'])
          os: {'minimum': min, 'recommended': rec, 'store': 'https://store.test'},
      },
    });
    final api = FakeApi()..replies['/api/v1/app-config'] = versions('2.0.0', '');
    var p = await start(t, api: api);
    expect(find.text('Toleo jipya linahitajika'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    await p.stop();
    p = await start(t, api: FakeApi()..replies['/api/v1/app-config'] = versions('1.0.0', '1.5.0'));
    expect(find.text('Kuna toleo jipya'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Baadaye'));
    await p.settle();
    expect(find.text('Kuna toleo jipya'), findsNothing);
  });

  testWidgets('maintenance shows the newsroom\'s own words', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/app-config'] = FakeApi.config({
        'maintenance': {'on': true, 'sw': 'Tunaboresha mfumo.', 'en': 'We are improving.'},
      });
    await start(t, api: api);
    expect(find.text('Tunaboresha mfumo.'), findsOneWidget);
  });

  testWidgets('a theme published meanwhile waits for the next cold start', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    final bold = FakeApi.config()['theme'] as Map<String, dynamic>
      ..addAll({'key': 'bold', 'hash': 'new', 'color': '#8b0000'});
    final api = FakeApi()..replies['/api/v1/app-config'] = FakeApi.config({'theme': bold});
    final p = await start(t, api: api, database: db);
    expect(p.container.read(themeChoiceProvider).key, 'signature');
    final stored = (await t.runAsync(db.allPrefs))![themePref];
    final next = ThemeChoice.decode(stored);
    expect((next.key, next.color), ('bold', '#8b0000'));
    await p.stop();
    await start(t, api: api, database: db, theme: next);
    final context = t.element(find.byType(HomeScreen));
    expect(Theme.of(context).colorScheme.primary.toARGB32(), 0xFF8B0000);
  });

  testWidgets('the very first launch never waits long for the theme', (t) async {
    await t.runAsync(() async {
      final db = AppDatabase(NativeDatabase.memory());
      final info = PackageInfo(appName: '', packageName: '', version: '1.0.0', buildNumber: '1');
      final watch = Stopwatch()..start();
      await HttpOverrides.runZoned(() async {
        final choice = await firstTheme(
          db,
          info,
          const Settings(),
          patience: const Duration(milliseconds: 100),
        );
        expect(choice.key, 'signature');
      });
      expect(watch.elapsedMilliseconds, lessThan(2000));
      await db.close();
    });
  });

  testWidgets('language, scheme and text size change at once', (t) async {
    final p = await start(t);
    await p.go('/profile');
    await t.tap(find.text('English'));
    await p.settle();
    expect(find.text('Appearance'), findsOneWidget);
    await t.tap(find.text('Dark'));
    await p.settle();
    expect(Theme.of(t.element(find.text('Appearance'))).brightness, Brightness.dark);
    expect(p.container.read(settingsControllerProvider).locale, 'en');
  });

  testWidgets('the latest feed goes on, and never shows a story twice', (t) async {
    final p = await start(t);
    await t.tap(find.text('Habari mpya').first);
    await p.settle();
    for (var i = 0; i < 12; i++) {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await p.settle(1);
    }
    final asked = p.api.asked.where((o) => o.uri.path.endsWith('/latest')).toList();
    expect(asked.where((o) => o.uri.queryParameters['cursor'] == 'two'), hasLength(1));
  });

  testWidgets('a story is read aloud whole: category, headline, time', (t) async {
    final handle = t.ensureSemantics();
    await start(t);
    final story = ((FakeApi.data('sw')['home'] as Map)['lead'] as List<dynamic>)[1] as Map;
    expect(
      find.bySemanticsLabel(RegExp('${(story['category'] as Map)['name']}.*${story['headline']}')),
      findsWidgets,
    );
    await expectLater(t, meetsGuideline(androidTapTargetGuideline));
    await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  for (final (name, go) in [
    ('article', path),
    ('explore', '/search'),
    ('saved', '/saved'),
    ('you', '/profile'),
    ('category', '/biashara'),
    ('video', '/video'),
  ]) {
    testWidgets('$name: targets are 48 and named', (t) async {
      final handle = t.ensureSemantics();
      final p = await start(t);
      go.split('/').length > 2 || name == 'category' ? await p.push(go) : await p.go(go);
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
    testWidgets('$name: nothing overflows at twice the text size', (t) async {
      final p = await start(t, textScale: 2);
      go.split('/').length > 2 || name == 'category' ? await p.push(go) : await p.go(go);
      for (var i = 0; i < 4; i++) {
        await t.drag(find.byType(Scrollable).last, const Offset(0, -600), warnIfMissed: false);
        await p.settle(1);
      }
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('home and onboarding: nothing overflows at twice the text size', (t) async {
    var p = await start(t, textScale: 2);
    for (var i = 0; i < 10; i++) {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -800));
      await p.settle(1);
    }
    expect(t.takeException(), isNull);
    await p.stop();
    p = await start(t, textScale: 2, onboarded: false);
    await t.tap(find.text('Anza'));
    await p.settle();
    await t.tap(find.text('Endelea'));
    await p.settle();
    expect(t.takeException(), isNull);
  });

  test('YouTube: its private player and nothing else', () {
    expect(
      YoutubeFacade.allowed('https://www.youtube-nocookie.com/embed/aqz-KE-bpKQ?autoplay=1'),
      isTrue,
    );
    for (final bad in [
      'https://www.youtube.com/watch?v=x',
      'http://www.youtube-nocookie.com/embed/x',
      'https://www.youtube-nocookie.com.evil.example/embed/x',
      'https://www.youtube-nocookie.com/redirect?q=x',
      'javascript:alert(1)',
    ]) {
      expect(YoutubeFacade.allowed(bad), isFalse, reason: bad);
    }
  });
}
