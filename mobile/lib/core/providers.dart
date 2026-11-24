import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:news_api_client/news_api_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'config/env.dart';
import 'config/theme_choice.dart';
import 'network/interceptors.dart';
import 'network/pinning.dart';
import 'storage/database.dart';
import 'storage/prefs.dart';
import 'telemetry/analytics.dart';

part 'providers.g.dart';

/// Opened by the bootstrap, before the first frame.
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) => throw UnimplementedError('overridden at start');

@Riverpod(keepAlive: true)
Settings initialSettings(Ref ref) => const Settings();

/// Applied for the whole session: a theme published meanwhile waits for the next cold start.
@Riverpod(keepAlive: true)
ThemeChoice themeChoice(Ref ref) => ThemeChoice.bundled();

@Riverpod(keepAlive: true)
PackageInfo packageInfo(Ref ref) =>
    PackageInfo(appName: '', packageName: '', version: '0.1.0', buildNumber: '1');

@Riverpod(keepAlive: true)
Analytics analytics(Ref ref) => const NoAnalytics();

/// Replaced in tests, so every "five minutes ago" is fixed.
@Riverpod(keepAlive: true)
DateTime Function() clockNow(Ref ref) => DateTime.now;

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  Settings build() => ref.watch(initialSettingsProvider);

  void change(Settings Function(Settings) edit) {
    final before = state;
    state = edit(before);
    unawaited(saveSettings(ref.read(databaseProvider), before, state));
  }
}

@Riverpod(keepAlive: true)
String localeName(Ref ref) => ref.watch(settingsControllerProvider.select((s) => s.locale));

/// One random id per installation, in the keychain. Read after the first frame; requests before it go without.
@Riverpod(keepAlive: true)
class DeviceId extends _$DeviceId {
  static const _key = 'device_id';

  @override
  String? build() => null;

  Future<void> load() async {
    const storage = FlutterSecureStorage();
    try {
      final found = await storage.read(key: _key);
      state = found ?? const Uuidish().v4();
      if (found == null) await storage.write(key: _key, value: state);
    } on Exception {
      state = null; // a locked keychain is not worth an error
    }
  }
}

@Riverpod(keepAlive: true)
Pinning pinning(Ref ref) => Pinning();

Dio buildDio({
  required AppDatabase db,
  required String Function() locale,
  required String? Function() deviceId,
  required PackageInfo info,
  Pinning? pinning,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  pinning?.install(dio);
  dio.interceptors.addAll([
    IdentityInterceptor(
      locale: locale,
      deviceId: deviceId,
      fixed: {
        'X-App-Version': info.version,
        'X-App-Build': info.buildNumber,
        'X-App-Platform': defaultTargetPlatform.name.toLowerCase(),
      },
    ),
    CacheInterceptor(db),
    RetryInterceptor(dio),
  ]);
  return dio;
}

@Riverpod(keepAlive: true)
Dio dio(Ref ref) => buildDio(
  db: ref.watch(databaseProvider),
  locale: () => ref.read(localeNameProvider),
  deviceId: () => ref.read(deviceIdProvider),
  info: ref.watch(packageInfoProvider),
  pinning: ref.watch(pinningProvider),
);

@Riverpod(keepAlive: true)
ContentApi contentApi(Ref ref) => ContentApi(ref.watch(dioProvider));

/// Without pins on purpose: this is the answer that can switch a wrong pin off.
@Riverpod(keepAlive: true)
AppConfigApi appConfigApi(Ref ref) => AppConfigApi(
  buildDio(
    db: ref.watch(databaseProvider),
    locale: () => ref.read(localeNameProvider),
    deviceId: () => ref.read(deviceIdProvider),
    info: ref.watch(packageInfoProvider),
  ),
);

/// Whether the phone believes it has a connection. The truth is in each request; this only says when to try again.
@Riverpod(keepAlive: true)
Stream<bool> online(Ref ref) async* {
  final connectivity = Connectivity();
  bool up(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);
  yield up(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(up).distinct();
}

/// On mobile data, with the saver on, videos wait for a tap.
@Riverpod(keepAlive: true)
bool autoplay(Ref ref) => !ref.watch(settingsControllerProvider.select((s) => s.dataSaver));
