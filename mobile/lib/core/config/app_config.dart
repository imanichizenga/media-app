import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:news_api_client/news_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/failures.dart';
import '../network/loaded.dart';
import '../providers.dart';
import 'theme_choice.dart';
import 'version.dart';

part 'app_config.g.dart';

const themePref = 'theme';

/// What the server says about this version of the app. The last answer is on the phone, so a start without a
/// connection still knows the brand, the flags and whether this version is allowed.
@Riverpod(keepAlive: true)
class AppConfigController extends _$AppConfigController {
  @override
  Future<AppConfig?> build() async {
    Future<Loaded<AppConfig>?> kept() =>
        fromCache((x) => ref.read(appConfigApiProvider).appConfig(extra: x));
    final cached = await kept();
    unawaited(Future(refresh));
    if (cached != null) _apply(cached.value);
    return cached?.value;
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final fresh = await fromNetwork((x) => ref.read(appConfigApiProvider).appConfig(extra: x));
      if (!ref.mounted) return;
      _apply(fresh.value);
      state = AsyncData(fresh.value);
      // Not now: the colours of a page must not change while it is read. Next start.
      final choice = ThemeChoice.of(fresh.value.theme);
      await ref.read(databaseProvider).putPref(themePref, choice.encode());
    } on Failure {
      // The last known answer stays.
    }
  }

  void _apply(AppConfig config) {
    ref.read(pinningProvider)
      ..pins = config.pinning.pins.toSet()
      ..enabled = config.pinning.enabled;
  }
}

enum Gate { open, update, maintenance }

@immutable
class AppStatus {
  const AppStatus({
    this.gate = Gate.open,
    this.store = '',
    this.recommended = '',
    this.message = '',
  });

  final Gate gate;
  final String store;

  /// A newer version worth mentioning, or empty.
  final String recommended;
  final String message;
}

@Riverpod(keepAlive: true)
AppStatus appStatus(Ref ref) {
  final config = ref.watch(appConfigControllerProvider).value;
  if (config == null) return const AppStatus();
  final version = ref.watch(packageInfoProvider).version;
  final mine = defaultTargetPlatform == TargetPlatform.iOS
      ? config.versions.ios
      : config.versions.android;
  if (config.maintenance.on_) {
    final locale = ref.watch(localeNameProvider);
    return AppStatus(
      gate: Gate.maintenance,
      message: locale == 'en' ? config.maintenance.en : config.maintenance.sw,
    );
  }
  if (isOlder(version, mine.minimum)) return AppStatus(gate: Gate.update, store: mine.store);
  return AppStatus(
    store: mine.store,
    recommended: isOlder(version, mine.recommended) ? mine.recommended : '',
  );
}

@Riverpod(keepAlive: true)
String mediaBase(Ref ref) {
  final base = ref.watch(appConfigControllerProvider).value?.mediaBaseUrl ?? '';
  // Local development serves media from the API itself.
  return base.isEmpty ? ref.watch(apiBaseProvider) : base;
}

@Riverpod(keepAlive: true)
String apiBase(Ref ref) => ref.watch(dioProvider).options.baseUrl;

@immutable
class Brand {
  const Brand({this.name = 'Mfano News', this.light, this.dark});

  final String name;
  final Logo? light;
  final Logo? dark;
}

@Riverpod(keepAlive: true)
Brand brand(Ref ref) {
  final who = ref.watch(appConfigControllerProvider).value?.identity;
  return who == null
      ? const Brand()
      : Brand(name: who.brandName, light: who.wordmarkLight, dark: who.wordmarkDark);
}

@Riverpod(keepAlive: true)
AppFlags flags(Ref ref) =>
    ref.watch(appConfigControllerProvider).value?.flags ??
    AppFlags(shorts: true, youtube: true, offlineSaving: true);
