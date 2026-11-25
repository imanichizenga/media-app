import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/shell.dart';
import '../../app/window.dart';
import '../../core/config/app_config.dart';
import '../../core/network/images.dart';
import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../article/text_size.dart';
import '../content/feeds.dart';
import '../explore/explore_screen.dart' show BigTitle, categoryIcons;

/// How the app behaves for this reader. The sign-in card joins in M4.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    tabAgain[4].addListener(_top);
  }

  @override
  void dispose() {
    tabAgain[4].removeListener(_top);
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    if (_scroll.hasClients) {
      unawaited(_scroll.animateTo(0, duration: NewsMotion.slow * 2, curve: NewsMotion.standard));
    }
  }

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.bg),
      child: Scaffold(
        body: ListView(
          controller: _scroll,
          padding: EdgeInsets.zero,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: articleWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BigTitle(s.navYou),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Group(
                            title: s.language,
                            icon: NewsIcons.languages,
                            child: Segmented(
                              labels: const ['Kiswahili', 'English'],
                              at: settings.locale == 'sw' ? 0 : 1,
                              onChanged: (i) =>
                                  change((x) => x.copyWith(locale: i == 0 ? 'sw' : 'en')),
                            ),
                          ),
                          _Group(
                            title: s.appearance,
                            icon: NewsIcons.sunMoon,
                            child: Segmented(
                              labels: [s.schemeSystem, s.schemeLight, s.schemeDark],
                              at: settings.scheme.index,
                              onChanged: (i) =>
                                  change((x) => x.copyWith(scheme: SchemeChoice.values[i])),
                            ),
                          ),
                          _Group(
                            title: s.textSize,
                            icon: NewsIcons.aLargeSmall,
                            child: const TextSizeControl(title: false),
                          ),
                          if (nav.isNotEmpty)
                            _Group(
                              title: s.topics,
                              icon: NewsIcons.layers,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final n in nav)
                                    NewsChip(
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
                                ],
                              ),
                            ),
                          _Group(
                            title: s.dataSaver,
                            icon: NewsIcons.gauge,
                            trailing: NewsSwitch(
                              label: s.dataSaver,
                              on: settings.dataSaver,
                              onChanged: (v) => change((x) => x.copyWith(dataSaver: v)),
                            ),
                            child: Text(
                              s.dataSaverBody,
                              style: context.type.bodyM.copyWith(color: c.textSecondary),
                            ),
                          ),
                          _Links([
                            (
                              NewsIcons.trash2,
                              s.clearCache,
                              () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await seenPictures.emptyCache();
                                await ref.read(databaseProvider).clearCache();
                                messenger.showSnackBar(SnackBar(content: Text(s.cacheCleared)));
                              },
                            ),
                          ]),
                          if (pages.isNotEmpty)
                            _Links([
                              for (final (icon, name, url) in pages)
                                (
                                  icon,
                                  name,
                                  () => unawaited(
                                    launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView),
                                  ),
                                ),
                            ]),
                          _Links([
                            (
                              NewsIcons.fileText,
                              s.licences,
                              () => showLicensePage(
                                context: context,
                                applicationName: brand.name,
                                applicationVersion: info.version,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 24),
                          const Center(child: Wordmark(size: 22, onDark: null)),
                          const SizedBox(height: 4),
                          Text(
                            s.version('${info.version} (${info.buildNumber})'),
                            textAlign: TextAlign.center,
                            style: context.type.caption.copyWith(color: c.textTertiary),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.icon, required this.child, this.trailing});

  final String title;
  final NewsIconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(NewsRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              NewsIcon(icon, size: 20, color: c.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.type.title.copyWith(color: c.textPrimary)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Links extends StatelessWidget {
  const _Links(this.rows);

  final List<(NewsIconData, String, VoidCallback)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(NewsRadius.xl),
      ),
      child: Column(
        children: [
          for (final (i, (icon, name, tap)) in rows.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(color: c.border),
              ),
            Pressable(
              onTap: tap,
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    NewsIcon(icon, size: 20, color: c.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name, style: context.type.bodyM.copyWith(color: c.textPrimary)),
                    ),
                    NewsIcon(NewsIcons.chevronRight, size: 18, color: c.textTertiary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class NewsSwitch extends StatelessWidget {
  const NewsSwitch({super.key, required this.label, required this.on, required this.onChanged});

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Semantics(
        toggled: on,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            onChanged(!on);
          },
          child: SizedBox(
            width: 56,
            height: 48,
            child: Center(
              child: AnimatedContainer(
                duration: context.still ? Duration.zero : NewsMotion.base,
                width: 52,
                height: 32,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: on ? c.textPrimary : c.surfaceSunken,
                  border: Border.all(color: on ? c.textPrimary : c.borderStrong),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedAlign(
                  duration: context.still ? Duration.zero : NewsMotion.base,
                  curve: NewsMotion.standard,
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: on ? c.bg : c.borderStrong,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
