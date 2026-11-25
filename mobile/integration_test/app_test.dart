import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/app/app.dart';
import 'package:news_app/core/config/app_config.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/providers.dart';
import 'package:news_app/core/storage/database.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/features/article/article_screen.dart';
import 'package:news_app/features/article/blocks.dart';
import 'package:news_app/features/home/home_screen.dart';
import 'package:news_app/features/video/shorts.dart';
import 'package:news_app/ui/adaptive/adaptive.dart';
import 'package:news_app/ui/components/cards.dart';
import 'package:news_app/ui/tokens/theme.dart';
import 'package:news_design_tokens/news_design_tokens.dart' show ThemeScheme;
import 'package:package_info_plus/package_info_plus.dart';

/// On a device, against an API filled by `seed_demo` whose app settings say: oldest version 0.1.0, theme Bold Ink.
/// flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> until(WidgetTester t, Finder f, {int seconds = 30}) async {
    for (var i = 0; i < seconds * 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
      if (f.evaluate().isNotEmpty) return;
    }
    fail('never appeared: $f');
  }

  /// A cold start on the given storage.
  Future<void> launch(
    WidgetTester t,
    AppDatabase db, {
    String version = '0.1.0',
    ThemeChoice? theme,
    String? dead,
  }) async {
    await t.pumpWidget(const SizedBox());
    final raw = await db.allPrefs();
    final settings = Settings.read(raw);
    await t.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        retry: (_, _) => null,
        overrides: [
          databaseProvider.overrideWithValue(db),
          initialSettingsProvider.overrideWithValue(settings),
          themeChoiceProvider.overrideWithValue(theme ?? ThemeChoice.decode(raw[themePref])),
          packageInfoProvider.overrideWithValue(
            PackageInfo(appName: '', packageName: '', version: version, buildNumber: '1'),
          ),
          if (dead != null)
            dioProvider.overrideWith(
              (ref) => buildDio(
                db: db,
                locale: () => settings.locale,
                deviceId: () => null,
                info: ref.watch(packageInfoProvider),
              )..options.baseUrl = dead,
            ),
        ],
        child: const NewsApp(),
      ),
    );
    await t.pump();
  }

  /// Brought clear of the bars first: how much of it shows depends on the phone.
  Future<void> openCover(WidgetTester t) async {
    final cover = find.byType(CoverCard).first;
    for (
      var i = 0;
      i < 6 && t.getCenter(cover).dy > t.view.physicalSize.height / t.view.devicePixelRatio * 0.6;
      i++
    ) {
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -200));
      await t.pump(const Duration(milliseconds: 600));
    }
    await t.tap(cover);
  }

  Future<AppDatabase> reader() async {
    final db = AppDatabase(NativeDatabase.memory());
    await saveSettings(db, const Settings(), const Settings(onboarded: true));
    return db;
  }

  Future<void> link(String path) =>
      // ignore: deprecated_member_use
      ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(
          MethodCall('pushRouteInformation', {'location': path, 'state': null}),
        ),
        (_) {},
      );

  Future<String> somePath(AppDatabase db) async {
    final home = await db.cached('/api/v1/content/home?locale=sw');
    final lead = (jsonDecode(home!.body) as Map<String, dynamic>)['lead'] as List<dynamic>;
    return (lead.last as Map<String, dynamic>)['path'] as String;
  }

  testWidgets('first launch → welcome, language, topics → home', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    await launch(t, db);
    await until(t, find.text('Anza'));
    await t.tap(find.text('Anza'));
    await until(t, find.text('Endelea'));
    await t.tap(find.text('Endelea'));
    await until(t, find.text('Anza'));
    await t.tap(find.text('Anza'));
    await until(t, find.byType(HomeScreen));
    await until(t, find.byType(CoverCard));
  });

  testWidgets('an article opens from its card, and from links, warm and cold', (t) async {
    final db = await reader();
    await launch(t, db);
    await until(t, find.byType(CoverCard));
    await until(t, find.textContaining('kusoma'));
    await openCover(t);
    await until(t, find.byType(ArticleBody));
    final path = await somePath(db);
    unawaited(link('https://dev.example.com$path'));
    await until(t, find.byWidgetPredicate((w) => w is ArticleScreen && w.path == path));
    await launch(t, db);
    unawaited(link(path));
    await until(t, find.byWidgetPredicate((w) => w is ArticleScreen && w.path == path));
  });

  testWidgets('what was saved is read without a network', (t) async {
    final db = await reader();
    await launch(t, db);
    await until(t, find.textContaining('kusoma'));
    await openCover(t);
    await until(t, find.byType(ArticleBody));
    await t.tap(
      find.descendant(of: find.byType(ActionBar), matching: find.bySemanticsLabel('Hifadhi')),
    );
    for (var i = 0; i < 100; i++) {
      await t.pump(const Duration(milliseconds: 200));
      final rows = await db.select(db.savedArticles).get();
      if (rows.isNotEmpty && rows.single.imagesReady) break;
    }
    expect((await db.select(db.savedArticles).get()).single.imagesReady, isTrue);
    await db.clearCache();
    await launch(t, db, dead: 'http://127.0.0.1:9');
    await until(t, find.text('Huna mtandao'), seconds: 40);
    await t.tap(find.text('Fungua zilizohifadhiwa'));
    await until(t, find.text('Inasomeka bila mtandao'));
    await t.tap(find.byType(RowCard).first);
    await until(t, find.byType(ArticleBody), seconds: 40);
  });

  testWidgets('twenty shorts', (t) async {
    final db = await reader();
    await launch(t, db);
    await until(t, find.byType(CoverCard));
    await t.tap(find.descendant(of: find.byType(PlacesBar), matching: find.text('Video')));
    final shorts = find.descendant(of: find.byType(Shorts), matching: find.byType(PageView));
    await until(t, shorts);
    for (var i = 0; i < 20; i++) {
      await t.fling(shorts, const Offset(0, -500), 2000);
      for (var k = 0; k < 5; k++) {
        await t.pump(const Duration(milliseconds: 120));
      }
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('a version that is no longer supported is told so', (t) async {
    final db = await reader();
    await launch(t, db, version: '0.0.1');
    await until(t, find.text('Toleo jipya linahitajika'));
  });

  testWidgets('a theme published in the admin waits for the next cold start', (t) async {
    final db = await reader();
    await launch(t, db, theme: ThemeChoice.bundled());
    await until(t, find.byType(CoverCard));
    for (var i = 0; i < 50; i++) {
      await t.pump(const Duration(milliseconds: 200));
      if ((await db.allPrefs()).containsKey(themePref)) break;
    }
    Color masthead() => t.element(find.byType(HomeScreen)).colors.mastheadBg;
    expect(masthead(), ThemeChoice.bundled().colors(ThemeScheme.light).mastheadBg);
    final next = ThemeChoice.decode((await db.allPrefs())[themePref]);
    expect(next.key, 'bold');
    await launch(t, db);
    await until(t, find.byType(CoverCard));
    expect(masthead(), next.colors(ThemeScheme.light).mastheadBg);
  });

  testWidgets('cold start to cached news', (t) async {
    final db = await reader();
    await launch(t, db);
    await until(t, find.textContaining('kusoma'));
    final watch = Stopwatch()..start();
    await launch(t, db, dead: 'http://127.0.0.1:9');
    while (find.textContaining('kusoma').evaluate().isEmpty) {
      await t.pump(const Duration(milliseconds: 16));
      if (watch.elapsedMilliseconds > 8000) fail('no cached news');
    }
    binding.reportData = {'cached_news_ms': watch.elapsedMilliseconds};
    debugPrint('PERF cached_news_ms ${watch.elapsedMilliseconds}');
    // A debug build on an emulator: the 1.5 s budget is for a profile build on a phone (G3).
    expect(watch.elapsedMilliseconds, lessThan(8000));
  });
}
