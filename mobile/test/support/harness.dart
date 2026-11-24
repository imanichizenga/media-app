import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' show AppConfigApi;
import 'package:news_app/app/app.dart';
import 'package:news_app/app/router.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/network/images.dart';
import 'package:news_app/core/network/interceptors.dart';
import 'package:news_app/core/providers.dart';
import 'package:news_app/core/storage/database.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/features/video/shorts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fake_api.dart';
import 'fake_video.dart';

export 'fake_api.dart';

/// Six minutes after the newest story of the seed, so every time on every screen is fixed.
final now = DateTime.parse(
  ((FakeApi.data('sw')['latest'] as List<dynamic>).first as Map<String, dynamic>)['published_at']
      as String,
).add(const Duration(minutes: 6));

final _pictures = <String, MemoryImage>{};

/// The seed's pictures, from files.
ImageProvider<Object> filePicture(String url) {
  final name = RegExp(r'/(?:i|v)/([0-9a-f]+)/').firstMatch(url)?[1];
  final file = File('test/fixtures/media/$name.jpg');
  return file.existsSync()
      ? _pictures[name!] ??= MemoryImage(file.readAsBytesSync())
      : MemoryImage(_grey);
}

final _grey = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0,
  0,
  0,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1, //
  8,
  6,
  0,
  0,
  0,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0,
  0,
  0,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x68,
  0x68,
  0x68, //
  0xF8,
  0x0F,
  0,
  0x05,
  0x84,
  0x02,
  0x80,
  0x8B,
  0xB4,
  0x2B,
  0x11,
  0,
  0,
  0,
  0,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82, //
]);

Future<void> loadFonts() async {
  for (final family in ['Newsreader', 'Inter']) {
    final loader = FontLoader(family)
      ..addFont(
        Future.value(ByteData.sublistView(File('assets/fonts/$family.ttf').readAsBytesSync())),
      );
    await loader.load();
  }
}

/// What was put away for reading without a connection.
class FakeKeeper implements PictureKeeper {
  final kept = <String>{};
  bool fail = false;

  @override
  Future<void> keep(String url) async => fail ? throw Exception('no') : kept.add(url);
  @override
  Future<void> drop(String url) async => kept.remove(url);
}

FakeKeeper keeper = FakeKeeper();

class Phone {
  Phone(this.tester, this.api, this.db, this.container);

  final WidgetTester tester;
  final FakeApi api;
  final AppDatabase db;
  final ProviderContainer container;

  /// Lets the network, the database and the pictures of the test arrive, then draws.
  Future<void> settle([int rounds = 6]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget as Image;
        await precacheImage(
          image.image,
          element,
          onError: (_, _) {},
        ).timeout(const Duration(milliseconds: 800), onTimeout: () {});
      }
    });
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// As if the app were closed. The database stays, as a phone's would.
  Future<void> stop() async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> go(String path) async {
    container.read(routerProvider).go(path);
    await settle();
  }

  Future<void> push(String path, {Object? extra}) async {
    container.read(routerProvider).push<void>(path, extra: extra);
    await settle();
  }
}

const phone = Size(390, 844);
const tablet = Size(1024, 1366);

/// The whole app on a device of the given size, with the seed's answers.
Future<Phone> start(
  WidgetTester tester, {
  Size size = phone,
  String locale = 'sw',
  SchemeChoice scheme = SchemeChoice.light,
  ThemeChoice? theme,
  bool onboarded = true,
  double textScale = 1,
  bool still = true,
  FakeApi? api,
  AppDatabase? database,
  String version = '1.0.0',
  bool settle = true,
  Set<String> topics = const {},
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = size * 2;
  tester.view.padding = const FakeViewPadding(top: 94, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 94, bottom: 48);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
    disableAnimations: still,
  );
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  // Everything a phone answers natively, answered with nothing.
  for (final name in [
    'plugins.it_nomads.com/flutter_secure_storage',
    'dev.fluttercommunity.plus/share',
  ]) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      MethodChannel(name),
      (_) async => null,
    );
  }

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  FakeVideo.install();
  keeper = FakeKeeper();
  final fake = api ?? FakeApi();
  final db = database ?? AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(
        Settings(onboarded: onboarded, locale: locale, scheme: scheme, topics: topics),
      ),
      themeChoiceProvider.overrideWithValue(theme ?? ThemeChoice.bundled()),
      packageInfoProvider.overrideWithValue(
        PackageInfo(appName: 'x', packageName: 'x', version: version, buildNumber: '1'),
      ),
      clockNowProvider.overrideWithValue(() => now),
      pictureLoaderProvider.overrideWithValue(filePicture),
      pictureKeeperProvider.overrideWithValue(keeper),
      makeControllerProvider.overrideWithValue(networkVideo),
      dioProvider.overrideWith((ref) => fakeDio(db, fake)),
      appConfigApiProvider.overrideWith((ref) => AppConfigApi(fakeDio(db, fake))),
      onlineProvider.overrideWith((ref) => Stream.value(!fake.offline)),
      ...overrides,
    ],
  );
  addTearDown(container.dispose); // the database lives in memory and goes with the test
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const NewsApp()));
  final p = Phone(tester, fake, db, container);
  if (settle) await p.settle(10);
  return p;
}

Dio fakeDio(AppDatabase db, FakeApi api) => Dio(BaseOptions(baseUrl: 'https://api.test'))
  ..httpClientAdapter = api
  ..interceptors.add(CacheInterceptor(db));

/// What is on the screen, as PNG bytes.
Future<Uint8List> capture(WidgetTester tester) async {
  final view = tester.binding.renderViews.first;
  // Tests draw shadows as solid slabs; a picture of the app must not.
  debugDisableShadows = false;
  void repaint(RenderObject o) {
    o.markNeedsPaint();
    o.visitChildren(repaint);
  }

  repaint(view);
  await tester.pump();
  final layer = view.debugLayer! as OffsetLayer;
  final bytes = await tester.runAsync(() async {
    final image = await layer.toImage(Offset.zero & tester.view.physicalSize);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  debugDisableShadows = true;
  return bytes!;
}
