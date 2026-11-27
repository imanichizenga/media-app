import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/account/session.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';

/// The reader, signing in first if need be (SPEC: one sheet, never a wall; intent resume). `intent` is the sheet's
/// title ("Sign in to like this story"); true once signed in, so the caller then does what was asked.
Future<bool> requireReader(BuildContext context, WidgetRef ref, {required String intent}) async {
  if (ref.read(readerProvider) != null) return true;
  final done = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SignInSheet(intent: intent),
  );
  return done == true && ref.read(readerProvider) != null;
}

enum _Step { phone, code, name }

class SignInSheet extends ConsumerStatefulWidget {
  const SignInSheet({super.key, required this.intent});

  final String intent;

  @override
  ConsumerState<SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends ConsumerState<SignInSheet> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  var _step = _Step.phone;
  var _busy = false;
  var _terms = false;
  String? _error;
  Sent? _sent;
  SignInMethods? _methods;
  var _wait = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref
          .read(sessionProvider.notifier)
          .methods()
          .then((m) => mounted ? setState(() => _methods = m) : null),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  String _say(Refused r, Strings s) => switch (r.code) {
    'invalid_phone' => s.errorPhone,
    'country_not_allowed' => s.errorCountry,
    'rate_limited' => s.errorWait,
    'code_wrong' => s.errorCodeWrong(r.attemptsLeft ?? 0),
    'code_expired' || 'code_locked' => s.errorCodeExpired,
    'sms_failed' || 'sms_not_configured' => s.errorSmsDown,
    _ => s.errorTryAgain,
  };

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
    } on Refused catch (r) {
      if (mounted) setState(() => _error = _say(r, Strings.of(context)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _countdown(int seconds) {
    _timer?.cancel();
    setState(() => _wait = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _wait <= 1) {
        t.cancel();
        if (mounted) setState(() => _wait = 0);
        return;
      }
      setState(() => _wait--);
    });
  }

  Future<void> _send() => _run(() async {
    final raw = _phone.text.replaceAll(RegExp(r'[\s()-]'), '');
    final phone = raw.startsWith('+') || raw.startsWith('0') ? raw : '+255$raw';
    final sent = await ref
        .read(sessionProvider.notifier)
        .requestCode(phone, ref.read(localeNameProvider));
    setState(() {
      _sent = sent;
      _step = _Step.code;
    });
    _countdown(sent.resendIn);
  });

  Future<void> _verify() => _run(() async {
    final reader = await ref.read(sessionProvider.notifier).verify(_sent!.challenge, _code.text);
    unawaited(HapticFeedback.lightImpact());
    if (reader.onboarding) {
      _name.text = reader.displayName;
      setState(() => _step = _Step.name);
    } else if (mounted) {
      Navigator.pop(context, true);
    }
  });

  Future<void> _finish() => _run(() async {
    if (!_terms) {
      setState(() => _error = Strings.of(context).acceptTerms);
      return;
    }
    await ref.read(sessionProvider.notifier).saveProfile({
      'display_name': _name.text,
      'accept_terms': true,
    });
    if (mounted) Navigator.pop(context, true);
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    final methods = _methods;
    final title = switch (_step) {
      _Step.phone => widget.intent,
      _Step.code => s.codeTitle,
      _Step.name => s.welcomeName,
    };
    Widget field(
      TextEditingController controller, {
      required String label,
      String? hint,
      TextInputType? keyboard,
      Iterable<String>? autofill,
      Widget? prefix,
      int? max,
      TextAlign align = TextAlign.start,
      ValueChanged<String>? onChanged,
      VoidCallback? onDone,
    }) => TextField(
      controller: controller,
      keyboardType: keyboard,
      autofillHints: autofill,
      maxLength: max,
      textAlign: align,
      autofocus: true,
      onChanged: onChanged,
      onSubmitted: (_) => onDone?.call(),
      style: type.bodyL.copyWith(color: c.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    final button = FilledButton(
      onPressed: _busy
          ? null
          : switch (_step) {
              _Step.phone => _send,
              _Step.code => _verify,
              _Step.name => _finish,
            },
      style: FilledButton.styleFrom(
        backgroundColor: c.brand,
        foregroundColor: c.onBrand,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: _busy
          // A pending state of a button, not a content loader.
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.onBrand),
            )
          : Text(switch (_step) {
              _Step.phone => s.sendCode,
              _Step.code => s.verify,
              _Step.name => s.continueOn,
            }, style: type.label.copyWith(color: c.onBrand, fontWeight: FontWeight.w600)),
    );
    final body = <Widget>[
      Semantics(
        header: true,
        child: Text(title, style: type.headlineM.copyWith(color: c.textPrimary)),
      ),
      const SizedBox(height: 6),
      if (_step == _Step.phone) ...[
        Text(s.signInLead, style: type.bodyM.copyWith(color: c.textSecondary)),
        const SizedBox(height: 20),
        if (methods == null)
          // The phone field's place, while the ways to sign in come.
          const Shimmer(child: Bone(width: double.infinity, height: 56, radius: 12))
        else if (methods.phone) ...[
          field(
            _phone,
            label: s.phoneLabel,
            hint: '712 345 678',
            keyboard: TextInputType.phone,
            autofill: const [AutofillHints.telephoneNumberNational],
            max: 20,
            prefix: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
              child: Text('🇹🇿 +255', style: type.bodyL.copyWith(color: c.textSecondary)),
            ),
            onDone: _send,
          ),
          const SizedBox(height: 6),
          Text(s.phoneHint, style: type.caption.copyWith(color: c.textSecondary)),
          const SizedBox(height: 16),
          button,
        ] else
          Text(s.errorSmsDown, style: type.bodyM.copyWith(color: c.textSecondary)),
      ],
      if (_step == _Step.code) ...[
        Text(s.codeLead(_sent?.phone ?? ''), style: type.bodyM.copyWith(color: c.textSecondary)),
        const SizedBox(height: 20),
        AutofillGroup(
          child: field(
            _code,
            label: s.codeLabel,
            keyboard: TextInputType.number,
            // iOS one-time-code and Android's SMS autofill fill this from the message.
            autofill: const [AutofillHints.oneTimeCode],
            max: 6,
            align: TextAlign.center,
            onChanged: (v) {
              if (v.replaceAll(RegExp(r'\D'), '').length == 6) unawaited(_verify());
            },
            onDone: _verify,
          ),
        ),
        if (_sent?.localCode case final local?) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(8)),
            child: Text(s.codeLocal(local), style: type.caption.copyWith(color: c.warning)),
          ),
        ],
        const SizedBox(height: 16),
        button,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() {
                _step = _Step.phone;
                _error = null;
              }),
              child: Text(s.codeChangePhone),
            ),
            TextButton(
              onPressed: _wait > 0 || _busy ? null : _send,
              child: Text(_wait > 0 ? s.codeResendIn(_wait) : s.codeResend),
            ),
          ],
        ),
      ],
      if (_step == _Step.name) ...[
        const SizedBox(height: 14),
        field(_name, label: s.nameLabel, autofill: const [AutofillHints.name], max: 80),
        const SizedBox(height: 6),
        Text(s.nameHint, style: type.caption.copyWith(color: c.textSecondary)),
        CheckboxListTile(
          value: _terms,
          onChanged: (v) => setState(() => _terms = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: c.brand,
          title: Text(s.acceptTerms, style: type.label.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: 8),
        button,
      ],
      if (_error case final error?) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              NewsIcon(NewsIcons.circleAlert, size: 18, color: c.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(error, style: type.label.copyWith(color: c.danger)),
              ),
            ],
          ),
        ),
      ],
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
        ),
      ),
    );
  }
}
