import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../../core/account/session.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import 'sign_in.dart';

/// At the top of You (ADR-0050, 0051): a guest is invited in; a reader sees their profile as others do, and
/// changes it in one sheet.
class AccountCard extends ConsumerWidget {
  const AccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reader = ref.watch(readerProvider);
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    final card = BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: c.border),
    );
    if (reader == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(22),
        decoration: card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: c.brandSoft,
              child: NewsIcon(NewsIcons.users, size: 26, color: c.brandText),
            ),
            const SizedBox(height: 14),
            Text(s.joinTitle, style: type.headlineM.copyWith(color: c.textPrimary)),
            const SizedBox(height: 6),
            Text(s.joinPoints, style: type.bodyM.copyWith(color: c.textSecondary)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => unawaited(requireReader(context, ref, intent: s.signInTitle)),
              style: FilledButton.styleFrom(
                backgroundColor: c.brand,
                foregroundColor: c.onBrand,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(s.signIn),
            ),
          ],
        ),
      );
    }
    final since = reader.joined == null
        ? ''
        : s.memberSince(DateFormat.yMMMM(ref.watch(localeNameProvider)).format(reader.joined!));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      decoration: card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 76,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [c.brand, c.brandStrong])),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -38),
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.brand,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 4),
                    ),
                    child: Text(
                      reader.initial,
                      style: type.display.copyWith(color: c.onBrand, fontSize: 34, height: 1),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reader.name, style: type.headlineM.copyWith(color: c.textPrimary)),
                      if (reader.username.isNotEmpty)
                        Text(
                          '@${reader.username}',
                          style: type.label.copyWith(color: c.textSecondary),
                        ),
                      if (since.isNotEmpty)
                        Text(since, style: type.caption.copyWith(color: c.textSecondary)),
                      const SizedBox(height: 10),
                      if (reader.bio.isNotEmpty)
                        Text(reader.bio, style: type.bodyM.copyWith(color: c.textPrimary))
                      else
                        GestureDetector(
                          onTap: () => unawaited(editProfile(context)),
                          child: Text(
                            '+ ${s.addBio}',
                            style: type.label.copyWith(
                              color: c.brandText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(editProfile(context)),
                  icon: NewsIcon(NewsIcons.penLine, size: 18, color: c.textPrimary),
                  label: Text(s.profileTitle),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textPrimary,
                    minimumSize: const Size.fromHeight(46),
                    side: BorderSide(color: c.borderStrong),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full name, username, bio, email; and whether one's name appears in reader lists. One sheet, one Save.
Future<void> editProfile(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const ProfileSheet(),
);

class ProfileSheet extends ConsumerStatefulWidget {
  const ProfileSheet({super.key});

  @override
  ConsumerState<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<ProfileSheet> {
  late final Reader _was = ref.read(readerProvider)!;
  late final _name = TextEditingController(text: _was.displayName);
  late final _handle = TextEditingController(text: _was.username);
  late final _bio = TextEditingController(text: _was.bio);
  late final _email = TextEditingController(text: _was.contactEmail);
  late var _hide = _was.hideFromReaders;
  var _busy = false;
  String? _error;
  String? _field;

  @override
  void dispose() {
    for (final c in [_name, _handle, _bio, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final s = Strings.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _field = null;
    });
    try {
      await ref.read(sessionProvider.notifier).saveProfile({
        'display_name': _name.text.trim(),
        'username': _handle.text.trim().replaceFirst(RegExp('^@'), ''),
        'bio': _bio.text.trim(),
        'contact_email': _email.text.trim(),
        'hide_from_readers': _hide,
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context);
      messenger?.showSnackBar(SnackBar(content: Text(s.profileSaved)));
    } on Refused catch (r) {
      setState(() {
        _field = r.field;
        _error = r.code == 'username_taken' ? s.usernameTaken : (r.detail ?? s.errorTryAgain);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    Widget field(
      TextEditingController controller, {
      required String name,
      required String label,
      String? hint,
      String? prefix,
      int lines = 1,
      int? max,
      TextInputType? keyboard,
      Iterable<String>? autofill,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: lines,
        minLines: lines,
        maxLength: max,
        keyboardType: keyboard,
        autofillHints: autofill,
        textCapitalization: name == 'display_name'
            ? TextCapitalization.words
            : TextCapitalization.none,
        autocorrect: name == 'bio',
        style: type.bodyL.copyWith(color: c.textPrimary),
        onChanged: (_) => name == 'bio' ? setState(() {}) : null,
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 2,
          prefixText: prefix,
          errorText: _field == name ? _error : null,
          counterText: name == 'bio' ? '${controller.text.length}/160' : '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(s.profileTitle, style: type.headlineM.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(height: 18),
              field(
                _name,
                name: 'display_name',
                label: s.fullName,
                max: 80,
                autofill: const [AutofillHints.name],
              ),
              field(
                _handle,
                name: 'username',
                label: s.username,
                hint: s.usernameHint,
                prefix: '@',
                max: 30,
                autofill: const [AutofillHints.username],
              ),
              field(_bio, name: 'bio', label: s.bio, hint: s.bioHint, lines: 3, max: 160),
              field(
                _email,
                name: 'contact_email',
                label: s.email,
                hint: s.emailHint,
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
              ),
              SwitchListTile.adaptive(
                value: _hide,
                onChanged: (v) => setState(() => _hide = v),
                contentPadding: EdgeInsets.zero,
                activeTrackColor: c.brand,
                title: Text(s.readersPrivate, style: type.label.copyWith(color: c.textPrimary)),
              ),
              if (_error != null && _field == null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: type.label.copyWith(color: c.danger)),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: c.brand,
                  foregroundColor: c.onBrand,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _busy
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.onBrand),
                      )
                    : Text(s.saveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// At the foot of You, for a reader only: leave, or go for good. Nothing else.
class AccountActions extends ConsumerWidget {
  const AccountActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(readerProvider) == null) return const SizedBox.shrink();
    final s = Strings.of(context);
    final c = context.colors;
    return SettingsGroup(
      title: s.accountActions,
      rows: [
        SettingsRow(
          icon: NewsIcons.logOut,
          title: s.signOut,
          onTap: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            await ref.read(sessionProvider.notifier).signOut();
            messenger?.showSnackBar(SnackBar(content: Text(s.signedOutToast)));
          },
        ),
        SettingsRow(
          icon: NewsIcons.trash2,
          title: s.deleteAccount,
          color: c.danger,
          onTap: () => unawaited(_delete(context, ref)),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final s = Strings.of(context);
    final sure = await confirm(
      context,
      title: s.deleteAccount,
      body: s.deleteConfirm,
      yes: s.deleteAccount,
      no: s.cancel,
    );
    if (sure) await ref.read(sessionProvider.notifier).delete();
  }
}
