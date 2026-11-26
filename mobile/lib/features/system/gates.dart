import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/states/designed.dart';

/// When the server says this version may not continue, nothing else is shown. One clear action.
class Gatekeeper extends ConsumerWidget {
  const Gatekeeper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);
    return switch (status.gate) {
      Gate.open => child,
      Gate.update => UpdateScreen(store: status.store),
      Gate.maintenance => MaintenanceScreen(message: status.message),
    };
  }
}

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key, required this.store});

  final String store;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return _Full(
      child: Designed(
        drawing: Drawing.empty,
        title: s.updateTitle,
        body: s.updateBody,
        action: store.isEmpty ? null : s.updateAction,
        onAction: () => launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication),
      ),
    );
  }
}

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    return _Full(
      child: Designed(
        drawing: Drawing.error,
        title: s.maintenanceTitle,
        body: message,
        action: s.retry,
        onAction: () => ref.read(appConfigControllerProvider.notifier).refresh(),
      ),
    );
  }
}

class _Full extends StatelessWidget {
  const _Full({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(24), child: Wordmark(size: 28)),
          Expanded(
            child: Center(child: SingleChildScrollView(child: child)),
          ),
          const SizedBox(height: 76),
        ],
      ),
    ),
  );
}
