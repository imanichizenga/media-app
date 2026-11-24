import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/format/format.dart';
import '../../core/network/failures.dart';
import '../../core/network/loaded.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';

/// What is shown is from earlier, and when. Absent while everything is fresh.
class StaleBanner extends ConsumerWidget {
  const StaleBanner({super.key, required this.loaded});

  final Loaded<Object?>? loaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (loaded?.failure is! OfflineFailure) return const SizedBox.shrink();
    final s = Strings.of(context);
    return _Strip(
      icon: NewsIcons.wifiOff,
      text: s.offlineBanner(ago(loaded!.at, s, ref.watch(clockNowProvider)())),
    );
  }
}

/// A newer version exists. Said once per version.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);
    final dismissed = ref.watch(settingsControllerProvider).dismissedVersion;
    if (status.recommended.isEmpty || status.store.isEmpty || dismissed == status.recommended) {
      return const SizedBox.shrink();
    }
    final s = Strings.of(context);
    return _Strip(
      icon: NewsIcons.download,
      text: s.updateSoft,
      action: s.updateAction,
      onAction: () => launchUrl(Uri.parse(status.store), mode: LaunchMode.externalApplication),
      onClose: () => ref
          .read(settingsControllerProvider.notifier)
          .change((x) => x.copyWith(dismissedVersion: status.recommended)),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.icon, required this.text, this.action, this.onAction, this.onClose});

  final NewsIconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(NewsSpace.s5, NewsSpace.s4, NewsSpace.s5, 0),
        padding: const EdgeInsets.only(left: NewsSpace.s4, right: NewsSpace.s1),
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(NewsRadius.lg),
        ),
        child: Row(
          children: [
            NewsIcon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: NewsSpace.s3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
                child: Text(text, style: context.type.label.copyWith(color: c.textPrimary)),
              ),
            ),
            if (action != null)
              Pressable(
                onTap: onAction,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s3),
                  child: Text(
                    action!,
                    style: context.type.label.copyWith(
                      color: c.textPrimary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            if (onClose != null)
              RoundButton(NewsIcons.x, label: Strings.of(context).later, onTap: onClose)
            else
              const SizedBox(width: NewsSpace.s3),
          ],
        ),
      ),
    );
  }
}
