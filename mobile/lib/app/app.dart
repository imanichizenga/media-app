import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../core/config/app_config.dart';
import '../core/providers.dart';
import '../core/storage/prefs.dart';
import '../core/telemetry/analytics.dart';
import '../features/saved/library.dart';
import '../features/system/gates.dart';
import '../l10n/gen/strings.dart';
import '../ui/tokens/theme.dart';
import 'router.dart';

class NewsApp extends ConsumerStatefulWidget {
  const NewsApp({super.key});

  @override
  ConsumerState<NewsApp> createState() => _NewsAppState();
}

class _NewsAppState extends ConsumerState<NewsApp> {
  late final ThemeData _light;
  late final ThemeData _dark;

  @override
  void initState() {
    super.initState();
    final choice = ref.read(themeChoiceProvider);
    _light = buildTheme(choice, ThemeScheme.light);
    _dark = buildTheme(choice, ThemeScheme.dark);
    // After the first frame: nothing here is needed to show cached news.
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_later()));
  }

  Future<void> _later() async {
    if (!mounted) return;
    ref.read(analyticsProvider).track(const AppOpened());
    await ref.read(deviceIdProvider.notifier).load();
    if (!mounted) return;
    await ref
        .read(databaseProvider)
        .evict(maxBytes: 24 * 1024 * 1024, maxAge: const Duration(days: 30));
    if (!mounted) return;
    await ref.read(libraryProvider.notifier).resumeDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => ref.read(brandProvider).name,
      routerConfig: ref.watch(routerProvider),
      theme: _light,
      darkTheme: _dark,
      themeMode: switch (settings.scheme) {
        SchemeChoice.system => ThemeMode.system,
        SchemeChoice.light => ThemeMode.light,
        SchemeChoice.dark => ThemeMode.dark,
      },
      locale: Locale(settings.locale),
      supportedLocales: Strings.supportedLocales,
      localizationsDelegates: const [Strings.delegate, ...GlobalMaterialLocalizations.delegates],
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayFor(context.colors.bg),
        child: Gatekeeper(child: child!),
      ),
    );
  }
}
