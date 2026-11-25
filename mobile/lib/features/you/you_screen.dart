import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:url_launcher/url_launcher.dart';

import '../../app/window.dart';
import '../../core/config/app_config.dart';
import '../../core/network/images.dart';
import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/adaptive/tops.dart';
import '../../ui/components/basics.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../article/text_size.dart';
import '../content/feeds.dart';
import '../explore/explore_screen.dart' show categoryIcons;

/// How the app behaves for this reader. The sign-in card joins in M4.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> with GoesToTop {
  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final c = context.colors;
    final settings = ref.watch(settingsControllerProvider);
    final change = ref.read(settingsControllerProvider.notifier).change;
    final links = ref.watch(appConfigControllerProvider).value?.links;
    final nav = ref.watch(navigationProvider).value?.value ?? const <NavigationItem>[];
    final brand = ref.watch(brandProvider);
    final info = ref.watch(packageInfoProvider);
    final pages = [
      (NewsIcons.info, s.linkAbout, links?.about ?? ''),
      (NewsIcons.penLine, s.linkEditorial, links?.editorial ?? ''),
      (NewsIcons.fileText, s.linkCorrections, links?.corrections ?? ''),
      (NewsIcons.mail, s.linkContact, links?.contact ?? ''),
      (NewsIcons.shield, s.linkPrivacy, links?.privacy ?? ''),
      (NewsIcons.scale, s.linkTerms, links?.terms ?? ''),
    ].where((p) => p.$3.isNotEmpty).toList();
    const languages = [('sw', 'Kiswahili'), ('en', 'English')];
    final schemes = [
      (SchemeChoice.system, s.schemeSystem),
      (SchemeChoice.light, s.schemeLight),
      (SchemeChoice.dark, s.schemeDark),
    ];
    String named<T>(List<(T, String)> options, T value) =>
        options.firstWhere((o) => o.$1 == value).$2;
    final groups = [
      SettingsGroup(
        rows: [
          SettingsRow(
            icon: NewsIcons.languages,
            title: s.language,
            value: named(languages, settings.locale),
            onTap: () async {
              final to = await choose(
                context,
                title: s.language,
                options: languages,
                current: settings.locale,
              );
              if (to != null) change((x) => x.copyWith(locale: to));
            },
          ),
          SettingsRow(
            icon: NewsIcons.sunMoon,
            title: s.appearance,
            value: named(schemes, settings.scheme),
            onTap: () async {
              final to = await choose(
                context,
                title: s.appearance,
                options: schemes,
                current: settings.scheme,
              );
              if (to != null) change((x) => x.copyWith(scheme: to));
            },
          ),
          SettingsRow(
            icon: NewsIcons.gauge,
            title: s.dataSaver,
            toggled: settings.dataSaver,
            onTap: () => change((x) => x.copyWith(dataSaver: !settings.dataSaver)),
            trailing: ExcludeSemantics(
              child: NewsSwitch(
                on: settings.dataSaver,
                onChanged: (v) => change((x) => x.copyWith(dataSaver: v)),
              ),
            ),
          ),
        ],
        note: s.dataSaverBody,
      ),
      SettingsGroup(
        title: s.textSize,
        rows: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextSizeControl(title: false),
          ),
        ],
      ),
      if (nav.isNotEmpty)
        SettingsGroup(
          title: s.topics,
          rows: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (final n in nav)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NewsChip(
                        n.name,
                        toggles: true,
                        on: settings.topics.contains(n.id),
                        icon: categoryIcons[n.icon],
                        onTap: () => change(
                          (x) => x.copyWith(
                            topics: x.topics.contains(n.id)
                                ? ({...x.topics}..remove(n.id))
                                : {...x.topics, n.id},
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      if (pages.isNotEmpty)
        SettingsGroup(
          title: s.aboutSection,
          rows: [
            for (final (icon, name, url) in pages)
              SettingsRow(
                icon: icon,
                title: name,
                onTap: () =>
                    unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView)),
              ),
          ],
        ),
      SettingsGroup(
        title: s.storage,
        rows: [
          SettingsRow(
            icon: NewsIcons.trash2,
            title: s.clearCache,
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              await seenPictures.emptyCache();
              await ref.read(databaseProvider).clearCache();
              messenger.showSnackBar(SnackBar(content: Text(s.cacheCleared)));
            },
          ),
          SettingsRow(
            icon: NewsIcons.fileText,
            title: s.licences,
            onTap: () => showLicensePage(
              context: context,
              applicationName: brand.name,
              applicationVersion: info.version,
              useRootNavigator: true,
            ),
          ),
        ],
      ),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.bg),
      child: Scaffold(
        body: NewsScroll(
          controller: scroll,
          header: [PlaceBar(s.navYou)],
          slivers: [
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: articleWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      ...groups,
                      const SizedBox(height: 16),
                      const Center(child: Wordmark(size: 22, onDark: null)),
                      const SizedBox(height: 4),
                      Text(
                        s.version('${info.version} (${info.buildNumber})'),
                        textAlign: TextAlign.center,
                        style: context.type.caption.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
