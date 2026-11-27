import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/account/session.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import 'sign_in.dart';

/// At the top of You (ADR-0050): a guest is invited in; a reader sees the account and can change or leave it.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    final reader = ref.watch(readerProvider);
    final box = BoxDecoration(
      color: c.surface,
      border: Border.all(color: c.border),
      borderRadius: BorderRadius.circular(14),
    );
    if (reader == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: box,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.joinTitle, style: type.headlineM.copyWith(color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(s.joinPoints, style: type.bodyM.copyWith(color: c.textSecondary)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => unawaited(requireReader(context, ref, intent: s.signInTitle)),
              style: FilledButton.styleFrom(
                backgroundColor: c.brand,
                foregroundColor: c.onBrand,
                minimumSize: const Size(120, 48),
              ),
              child: Text(s.signIn),
            ),
          ],
        ),
      );
    }
    Widget action(NewsIconData icon, String label, VoidCallback onTap, {Color? color}) =>
        OutlinedButton.icon(
          onPressed: onTap,
          icon: NewsIcon(icon, size: 18, color: color ?? c.textPrimary),
          label: Text(label, style: type.label.copyWith(color: color ?? c.textPrimary)),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: box,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
                child: Text(reader.initial, style: type.headlineL.copyWith(color: c.onBrand)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reader.name, style: type.headlineS.copyWith(color: c.textPrimary)),
                    if (reader.username.isNotEmpty)
                      Text(
                        '@${reader.username}',
                        style: type.label.copyWith(color: c.textSecondary),
                      ),
                    Text(
                      reader.phone.isNotEmpty ? reader.phone : reader.email,
                      style: type.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.editName,
                onPressed: () => unawaited(_rename(context, ref, reader)),
                icon: NewsIcon(NewsIcons.penLine, size: 20, color: c.textSecondary),
              ),
            ],
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: reader.hideFromReaders,
            activeTrackColor: c.brand,
            title: Text(s.readersPrivate, style: type.label.copyWith(color: c.textPrimary)),
            onChanged: (on) => unawaited(
              ref.read(sessionProvider.notifier).saveProfile({'hide_from_readers': on}),
            ),
          ),
          Divider(color: c.border),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              action(NewsIcons.logOut, s.signOut, () async {
                await ref.read(sessionProvider.notifier).signOut();
                if (context.mounted) {
                  ScaffoldMessenger.maybeOf(context)
                      ?.showSnackBar(SnackBar(content: Text(s.signedOutToast)));
                }
              }),
              action(NewsIcons.download, s.downloadData, () async {
                final json = await ref.read(sessionProvider.notifier).export();
                // Everything kept about the reader, handed to wherever they want it (PDPA Tanzania 2022).
                final file = XFile.fromData(
                  utf8.encode(json),
                  mimeType: 'application/json',
                  name: 'my-data.json',
                );
                await SharePlus.instance.share(ShareParams(files: [file]));
              }),
              action(
                NewsIcons.trash2,
                s.deleteAccount,
                () => unawaited(_delete(context, ref)),
                color: c.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, Reader reader) async {
    final s = Strings.of(context);
    final field = TextEditingController(text: reader.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(s.editName),
        content: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: field,
            autofocus: true,
            maxLength: 80,
            decoration: InputDecoration(labelText: s.nameLabel),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: Text(s.saveChanges),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.trim().length < 2) return;
    try {
      await ref.read(sessionProvider.notifier).saveProfile({'display_name': name});
    } on Refused {
      // The field said what was wrong.
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final s = Strings.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(s.deleteAccount),
        content: Text(s.deleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.deleteAccount, style: TextStyle(color: context.colors.danger)),
          ),
        ],
      ),
    );
    if (sure == true) await ref.read(sessionProvider.notifier).delete();
  }
}
