import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' show AppConfigApi;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/config/app_config.dart' show themePref;
import '../core/config/env.dart';
import '../core/config/theme_choice.dart';
import '../core/providers.dart';
import '../core/storage/database.dart';
import '../core/storage/prefs.dart';
import 'app.dart';

/// Only what the first frame needs: the database, the settings, the theme.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Bounded, whatever the phone has.
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 96 * 1024 * 1024
    ..maximumSize = 300;
  final db = AppDatabase();
  final (raw, info) = await (db.allPrefs(), PackageInfo.fromPlatform()).wait;
  final settings = Settings.read(raw);
  final theme = raw.containsKey(themePref)
      ? ThemeChoice.decode(raw[themePref])
      : await firstTheme(db, info, settings);
  Widget app() => ProviderScope(
    retry: (_, _) => null,
    overrides: [
      databaseProvider.overrideWithValue(db),
      initialSettingsProvider.overrideWithValue(settings),
      themeChoiceProvider.overrideWithValue(theme),
      packageInfoProvider.overrideWithValue(info),
    ],
    child: const NewsApp(),
  );
  if (Env.sentryDsn.isEmpty) return runApp(app());
  await SentryFlutter.init((o) {
    o
      ..dsn = Env.sentryDsn
      ..environment = Env.flavor
      ..release = 'news-app@${info.version}+${info.buildNumber}'
      ..dist = info.buildNumber
      ..sendDefaultPii = false
      ..tracesSampleRate = 0;
  }, appRunner: () => runApp(app()));
}

/// The very first launch waits a moment for the published theme, while the splash is still up. Later launches use the
/// one they know, and a newer one waits for the next start.
Future<ThemeChoice> firstTheme(
  AppDatabase db,
  PackageInfo info,
  Settings settings, {
  Duration patience = const Duration(milliseconds: 1200),
}) async {
  try {
    final api = AppConfigApi(
      buildDio(db: db, locale: () => settings.locale, deviceId: () => null, info: info),
    );
    final config = await api.appConfig().timeout(patience);
    final choice = ThemeChoice.of(config.data!.theme);
    await db.putPref(themePref, choice.encode());
    return choice;
  } on Object {
    return ThemeChoice.bundled();
  }
}
