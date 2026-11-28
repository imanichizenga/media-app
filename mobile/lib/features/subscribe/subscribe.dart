import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/account/session.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/premium.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/premium.dart';
import '../../ui/tokens/theme.dart';
import '../account/sign_in.dart';

// Paid reading (ADR-0052): the same plans, paywall and payments as the website, through the same API.

/// One plan, as the API says it in the reader's language.
class PlanOffer {
  PlanOffer(Map<String, dynamic> j)
    : id = j['id'] as String,
      interval = j['interval'] as String,
      price = j['price'] as int,
      name = j['name'] as String,
      tagline = j['tagline'] as String? ?? '',
      features = [for (final f in j['features'] as List<dynamic>? ?? const []) f as String],
      badge = j['badge'] as String? ?? '',
      tone = j['tone'] as String? ?? 'brand',
      highlighted = j['highlighted'] as bool? ?? false,
      monthly = j['monthly_equivalent'] as int? ?? j['price'] as int;

  final String id, interval, name, tagline, badge, tone;
  final int price, monthly;
  final List<String> features;
  final bool highlighted;
  bool get yearly => interval == 'year';
}

class Offer {
  Offer(Map<String, dynamic> j)
    : enabled = j['enabled'] as bool? ?? false,
      methods = [for (final m in j['methods'] as List<dynamic>? ?? const []) m as String],
      plans = [
        for (final p in j['plans'] as List<dynamic>? ?? const [])
          PlanOffer(p as Map<String, dynamic>),
      ];

  final bool enabled;
  final List<String> methods;
  final List<PlanOffer> plans;
  int? get from {
    final monthly = plans.where((p) => !p.yearly).map((p) => p.price);
    return monthly.isEmpty ? null : monthly.reduce((a, b) => a < b ? a : b);
  }
}

String money(int n, String locale) => NumberFormat.currency(
  locale: locale == 'en' ? 'en' : 'sw',
  symbol: 'TSh ',
  decimalDigits: 0,
).format(n);

final offerProvider = FutureProvider.autoDispose.family<Offer, String>((ref, locale) async {
  final r = await ref
      .watch(dioProvider)
      .get<Map<String, dynamic>>(
        '/api/v1/subscriptions/plans',
        queryParameters: {'locale': locale},
      );
  return Offer(r.data!);
});

/// The whole of a story for subscribers, for a reader with paid time left; null for anyone else.
final fullStoryProvider = FutureProvider.autoDispose.family<Article?, (String, String)>((
  ref,
  key,
) async {
  if (ref.watch(readerProvider) == null) return null;
  final (post, locale) = key;
  try {
    final r = await ref
        .watch(dioProvider)
        .get<Map<String, dynamic>>(
          '/api/v1/subscriptions/posts/$post',
          queryParameters: {'locale': locale},
        );
    return Article.fromJson(r.data!);
  } on DioException catch (e) {
    if (const {401, 402, 403, 404}.contains(e.response?.statusCode)) return null;
    rethrow;
  }
});

/// The end of a story's opening: an invitation, with the price; the rest of the app stays where it is.
class Paywall extends ConsumerWidget {
  const Paywall({super.key, required this.path, required this.locale, required this.unlocking});

  final String path;
  final String locale;
  final bool unlocking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = Strings.of(context);
    final from = ref.watch(offerProvider(locale)).value?.from;
    final signedIn = ref.watch(readerProvider) != null;
    return Padding(
      padding: const EdgeInsets.only(top: NewsSpace.s2, bottom: NewsSpace.s6),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              NewsSpace.s6,
              NewsSpace.s8,
              NewsSpace.s6,
              NewsSpace.s6,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(NewsRadius.lg),
              border: Border.all(color: c.border),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [Premium.wash, c.surface],
              ),
              boxShadow: Premium.card,
            ),
            child: Column(
              children: [
                const Crown(),
                const SizedBox(height: NewsSpace.s4),
                Text(
                  s.paywallTitle,
                  textAlign: TextAlign.center,
                  style: context.type.headlineM.merge(context.type.serif),
                ),
                const SizedBox(height: NewsSpace.s2),
                Text(
                  s.paywallText,
                  textAlign: TextAlign.center,
                  style: context.type.bodyM.copyWith(color: c.textSecondary),
                ),
                if (from != null) ...[
                  const SizedBox(height: NewsSpace.s3),
                  Text(
                    s.paywallFrom(money(from, locale)),
                    style: context.type.label.copyWith(
                      color: c.brandText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: NewsSpace.s5),
                if (unlocking)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Turning(size: 16),
                      const SizedBox(width: NewsSpace.s2),
                      Text(s.paywallUnlocking, style: context.type.label),
                    ],
                  )
                else ...[
                  NewsButton(
                    s.paywallAction,
                    icon: NewsIcons.crown,
                    wide: true,
                    onTap: () => context.push(
                      Uri(path: '/subscribe', queryParameters: {'next': path}).toString(),
                    ),
                  ),
                  if (!signedIn) ...[
                    const SizedBox(height: NewsSpace.s2),
                    NewsButton(
                      s.paywallSignIn,
                      kind: ButtonKind.quiet,
                      onTap: () =>
                          unawaited(requireReader(context, ref, intent: s.signInToSubscribe)),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: NewsSpace.s3),
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: NewsIcon(NewsIcons.arrowLeft, size: 16, color: c.textSecondary),
            label: Text(s.paywallFree, style: context.type.label.copyWith(color: c.textSecondary)),
          ),
        ],
      ),
    );
  }
}

/// Fades the last lines of a story's opening into the page.
class FadeOut extends StatelessWidget {
  const FadeOut({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: Premium.fade.createShader,
    child: child,
  );
}

// ---- the plans ----
class SubscribeScreen extends ConsumerStatefulWidget {
  const SubscribeScreen({super.key, required this.next});
  final String next;

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  var _yearly = false;
  String? _chosen;

  String get _locale => Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'sw';

  PlanOffer? _pick(List<PlanOffer> list) {
    if (list.isEmpty) return null;
    final found = list.where((p) => p.id == _chosen);
    if (found.isNotEmpty) return found.first;
    final top = list.where((p) => p.highlighted);
    return top.isNotEmpty ? top.first : list.first;
  }

  Future<void> _continue(Offer offer, PlanOffer plan) async {
    final s = Strings.of(context);
    if (!await requireReader(context, ref, intent: s.signInToSubscribe)) return;
    if (!mounted) return;
    final paid = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PaySheet(plan: plan, methods: offer.methods, locale: _locale),
    );
    if (paid == true && mounted) {
      ref.invalidate(fullStoryProvider);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    final offer = ref.watch(offerProvider(_locale));
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: c.bg,
        title: Text(s.plansTitle, style: context.type.title),
      ),
      body: offer.when(
        loading: () => const _PlansBones(),
        error: (_, _) => Center(
          child: NewsButton(s.payTryAgain, onTap: () => ref.invalidate(offerProvider(_locale))),
        ),
        data: (o) {
          final monthly = o.plans.where((p) => !p.yearly).toList();
          final yearly = o.plans.where((p) => p.yearly).toList();
          final list = _yearly && yearly.isNotEmpty
              ? yearly
              : (monthly.isNotEmpty ? monthly : yearly);
          final plan = _pick(list);
          final save = yearly.where((p) => p.badge.isNotEmpty).map((p) => p.badge).firstOrNull;
          final usable = o.enabled && o.plans.isNotEmpty && o.methods.isNotEmpty;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    NewsSpace.s5,
                    NewsSpace.s4,
                    NewsSpace.s5,
                    NewsSpace.s6,
                  ),
                  children: [
                    const Center(child: Crown(size: 52)),
                    const SizedBox(height: NewsSpace.s4),
                    Text(
                      s.plansTitle,
                      textAlign: TextAlign.center,
                      style: context.type.headlineL.merge(context.type.serif),
                    ),
                    const SizedBox(height: NewsSpace.s2),
                    Text(
                      s.plansLead,
                      textAlign: TextAlign.center,
                      style: context.type.bodyM.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: NewsSpace.s6),
                    if (!usable)
                      Text(
                        o.plans.isEmpty ? s.plansNone : s.payUnavailable,
                        textAlign: TextAlign.center,
                      )
                    else ...[
                      if (monthly.isNotEmpty && yearly.isNotEmpty)
                        Center(
                          child: _Interval(
                            yearly: _yearly,
                            save: save,
                            onChange: (y) => setState(() {
                              _yearly = y;
                              _chosen = null;
                            }),
                          ),
                        ),
                      const SizedBox(height: NewsSpace.s6),
                      for (final p in list) ...[
                        _PlanCard(
                          plan: p,
                          locale: _locale,
                          chosen: p.id == plan?.id,
                          onTap: () => setState(() => _chosen = p.id),
                        ),
                        const SizedBox(height: NewsSpace.s5),
                      ],
                      Text(
                        s.plansFine,
                        textAlign: TextAlign.center,
                        style: context.type.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (usable && plan != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(
                      NewsSpace.s5,
                      NewsSpace.s3,
                      NewsSpace.s5,
                      NewsSpace.s3,
                    ),
                    child: NewsButton(
                      s.plansContinue,
                      wide: true,
                      onTap: () => unawaited(_continue(o, plan)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Interval extends StatelessWidget {
  const _Interval({required this.yearly, required this.save, required this.onChange});
  final bool yearly;
  final String? save;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    Widget side(String label, bool on, bool value, {String? chip}) => GestureDetector(
      onTap: () => onChange(value),
      child: AnimatedContainer(
        duration: NewsMotion.base,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: on ? c.surface : Premium.clear,
          borderRadius: BorderRadius.circular(999),
          boxShadow: on ? Premium.raised : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: context.type.label.copyWith(fontWeight: FontWeight.w600)),
            if (chip != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: c.successSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chip,
                  style: context.type.caption.copyWith(
                    fontSize: 10.5,
                    color: c.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            side(s.plansMonthly, !yearly, false),
            side(s.plansYearly, yearly, true, chip: save),
          ],
        ),
      ),
    );
  }
}

/// Netflix's way: the plan's colour and name on top, then what it costs and gives, line by line.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.locale,
    required this.chosen,
    required this.onTap,
  });
  final PlanOffer plan;
  final String locale;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    final per = plan.yearly ? s.perYear : s.perMonth;
    return Semantics(
      button: true,
      selected: chosen,
      label: '${plan.name}, ${money(plan.price, locale)} $per',
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: NewsMotion.base,
              padding: const EdgeInsets.all(NewsSpace.s2),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(NewsRadius.lg),
                border: Border.all(
                  color: chosen ? c.textPrimary : c.border,
                  width: chosen ? 3 : 1.5,
                ),
                boxShadow: chosen ? Premium.chosen : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 104),
                    padding: const EdgeInsets.all(NewsSpace.s4),
                    decoration: BoxDecoration(
                      gradient: Premium.tone(plan.tone, c),
                      borderRadius: BorderRadius.circular(NewsRadius.md),
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: context.type.headlineS.copyWith(
                                  color: Premium.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (plan.tagline.isNotEmpty)
                                Text(
                                  plan.tagline,
                                  style: context.type.caption.copyWith(color: Premium.inkSoft),
                                ),
                            ],
                          ),
                        ),
                        if (chosen)
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Premium.ink,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: NewsIcon(
                                  NewsIcons.check,
                                  size: 16,
                                  color: c.textPrimary,
                                  stroke: 3,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NewsSpace.s2,
                      NewsSpace.s3,
                      NewsSpace.s2,
                      NewsSpace.s1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                plan.yearly ? s.plansYearly : s.plansMonthly,
                                style: context.type.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                            Text(
                              money(plan.price, locale),
                              style: context.type.headlineS.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(per, style: context.type.caption.copyWith(color: c.textSecondary)),
                          ],
                        ),
                        if (plan.yearly) ...[
                          Divider(height: NewsSpace.s5, color: c.border),
                          Text(
                            s.plansEquivalent(money(plan.monthly, locale)),
                            style: context.type.caption.copyWith(
                              color: c.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        for (final f in plan.features) ...[
                          Divider(height: NewsSpace.s5, color: c.border),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NewsIcon(NewsIcons.check, size: 16, color: c.brandText, stroke: 2.5),
                              const SizedBox(width: NewsSpace.s2),
                              Expanded(child: Text(f, style: context.type.label)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (plan.badge.isNotEmpty)
              Positioned(
                top: -11,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.textPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      plan.badge.toUpperCase(),
                      style: context.type.caption.copyWith(
                        fontSize: 10.5,
                        color: c.bg,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
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

// ---- paying ----
enum _Step { method, wait, card, done, failed }

class PaySheet extends ConsumerStatefulWidget {
  const PaySheet({super.key, required this.plan, required this.methods, required this.locale});
  final PlanOffer plan;
  final List<String> methods;
  final String locale;

  @override
  ConsumerState<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends ConsumerState<PaySheet> with WidgetsBindingObserver {
  final _phone = TextEditingController();
  late String _method = widget.methods.contains('mobile') ? 'mobile' : widget.methods.first;
  var _step = _Step.method;
  var _busy = false;
  String? _error;
  String? _payment;
  String _until = '';
  Timer? _timer;
  DateTime _deadline = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final mine = ref.read(readerProvider)?.phone ?? '';
    _phone.text = mine.startsWith('+255') ? mine.substring(4) : '';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _phone.dispose();
    super.dispose();
  }

  /// Back from the card checkout: look again at once.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _payment != null && _step != _Step.done) {
      unawaited(_check());
    }
  }

  Future<void> _pay() async {
    final s = Strings.of(context);
    var phone = '';
    if (_method == 'mobile') {
      final raw = _phone.text.replaceAll(RegExp(r'[\s()-]'), '');
      phone = raw.startsWith('+') || raw.startsWith('0') ? raw : '+255$raw';
      if (!RegExp(r'^(\+255|0)[67]\d{8}$').hasMatch(phone)) {
        setState(() => _error = s.payPhoneInvalid);
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/api/v1/subscriptions/checkout',
            data: {
              'plan': widget.plan.id,
              'method': _method,
              'phone': phone,
              'return_path': '/subscribe',
            },
          );
      final data = r.data!;
      _payment = data['id'] as String;
      _deadline = DateTime.now().add(const Duration(minutes: 5));
      if (_method == 'card') {
        final url = data['checkout_url'] as String? ?? '';
        setState(() => _step = url.isEmpty ? _Step.failed : _Step.card);
        if (url.isEmpty) {
          _error = s.payUnavailable;
          return;
        }
        unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView));
      } else {
        setState(() => _step = _Step.wait);
      }
      _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) => unawaited(_check()));
    } on DioException catch (e) {
      final body = e.response?.data;
      final field = body is Map ? body['field'] : null;
      setState(() {
        _error = field == 'phone'
            ? s.payPhoneInvalid
            : (e.response?.statusCode == 503 ? s.payUnavailable : s.payFailed);
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    final id = _payment;
    if (id == null || !mounted) return;
    try {
      final r = await ref
          .read(dioProvider)
          .get<Map<String, dynamic>>(
            '/api/v1/subscriptions/payments/$id',
            queryParameters: {'locale': widget.locale},
          );
      final data = r.data!;
      final status = data['status'] as String;
      if (!mounted) return;
      final s = Strings.of(context);
      if (status == 'completed') {
        _timer?.cancel();
        final ends = (data['subscription'] as Map?)?['ends_at'] as String?;
        _until = ends == null
            ? ''
            : DateFormat.yMMMMd(widget.locale == 'en' ? 'en' : 'sw')
                  .format(DateTime.parse(ends).toLocal());
        unawaited(HapticFeedback.mediumImpact());
        setState(() => _step = _Step.done);
      } else if (status != 'pending' || DateTime.now().isAfter(_deadline)) {
        _timer?.cancel();
        setState(() {
          _error = status == 'expired' || status == 'pending' ? s.payExpired : s.payFailed;
          _step = _Step.failed;
        });
      }
    } on DioException {
      // A moment without network: the next tick asks again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    final price = money(widget.plan.price, widget.locale);
    final per = widget.plan.yearly ? s.perYear : s.perMonth;
    final body = switch (_step) {
      _Step.method => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.payTitle(widget.plan.name),
            style: context.type.headlineM.merge(context.type.serif),
          ),
          const SizedBox(height: 4),
          Text('$price $per', style: context.type.bodyM.copyWith(color: c.textSecondary)),
          const SizedBox(height: NewsSpace.s5),
          if (widget.methods.contains('mobile'))
            _Method(
              icon: NewsIcons.smartphone,
              title: s.payMobile,
              hint: s.payMobileHint,
              on: _method == 'mobile',
              onTap: () => setState(() => _method = 'mobile'),
            ),
          if (widget.methods.contains('card')) ...[
            const SizedBox(height: NewsSpace.s3),
            _Method(
              icon: NewsIcons.creditCard,
              title: s.payCard,
              hint: s.payCardHint,
              on: _method == 'card',
              onTap: () => setState(() => _method = 'card'),
            ),
          ],
          if (_method == 'mobile') ...[
            const SizedBox(height: NewsSpace.s5),
            Text(s.payPhone, style: context.type.label.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: NewsSpace.s2),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              decoration: InputDecoration(
                prefixText: '🇹🇿 +255  ',
                hintText: '712 345 678',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(NewsRadius.sm)),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: NewsSpace.s3),
            Container(
              padding: const EdgeInsets.all(NewsSpace.s3),
              decoration: BoxDecoration(
                color: c.dangerSoft,
                borderRadius: BorderRadius.circular(NewsRadius.sm),
              ),
              child: Text(_error!, style: context.type.label.copyWith(color: c.danger)),
            ),
          ],
          const SizedBox(height: NewsSpace.s5),
          NewsButton(
            s.payButton(price),
            icon: NewsIcons.lockKeyhole,
            wide: true,
            pending: _busy,
            onTap: _busy ? null : _pay,
          ),
          const SizedBox(height: NewsSpace.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NewsIcon(NewsIcons.lockKeyhole, size: 13, color: c.textSecondary),
              const SizedBox(width: 6),
              Text(s.paySecure, style: context.type.caption.copyWith(color: c.textSecondary)),
            ],
          ),
        ],
      ),
      _Step.wait || _Step.card => Column(
        children: [
          const SizedBox(height: NewsSpace.s4),
          _Pulse(icon: _step == _Step.wait ? NewsIcons.smartphone : NewsIcons.creditCard),
          const SizedBox(height: NewsSpace.s5),
          Text(
            _step == _Step.wait ? s.payWaitTitle : s.payCardRedirect,
            textAlign: TextAlign.center,
            style: context.type.headlineM.merge(context.type.serif),
          ),
          const SizedBox(height: NewsSpace.s2),
          if (_step == _Step.wait)
            Text(
              s.payWaitText('+255 ${_phone.text.replaceAll(RegExp(r'^0'), '')}'),
              textAlign: TextAlign.center,
              style: context.type.bodyM.copyWith(color: c.textSecondary),
            ),
          const SizedBox(height: NewsSpace.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Turning(size: 14),
              const SizedBox(width: NewsSpace.s2),
              Text(s.payChecking, style: context.type.caption.copyWith(color: c.textSecondary)),
            ],
          ),
          const SizedBox(height: NewsSpace.s6),
        ],
      ),
      _Step.done => Column(
        children: [
          const SizedBox(height: NewsSpace.s4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 480),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Premium.gold),
              child: const Center(
                child: NewsIcon(NewsIcons.circleCheck, size: 48, color: Premium.ink),
              ),
            ),
          ),
          const SizedBox(height: NewsSpace.s5),
          Text(
            s.paySuccessTitle,
            textAlign: TextAlign.center,
            style: context.type.headlineM.merge(context.type.serif),
          ),
          const SizedBox(height: NewsSpace.s2),
          if (_until.isNotEmpty)
            Text(
              s.paySuccessText(_until),
              style: context.type.bodyM.copyWith(color: c.textSecondary),
            ),
          const SizedBox(height: NewsSpace.s6),
          NewsButton(s.payContinue, wide: true, onTap: () => Navigator.of(context).pop(true)),
        ],
      ),
      _Step.failed => Column(
        children: [
          const SizedBox(height: NewsSpace.s4),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.dangerSoft),
            child: Center(child: NewsIcon(NewsIcons.x, size: 36, color: c.danger)),
          ),
          const SizedBox(height: NewsSpace.s4),
          Text(_error ?? s.payFailed, textAlign: TextAlign.center, style: context.type.bodyL),
          const SizedBox(height: NewsSpace.s5),
          NewsButton(
            s.payTryAgain,
            wide: true,
            onTap: () => setState(() {
              _step = _Step.method;
              _error = null;
              _payment = null;
            }),
          ),
        ],
      ),
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(
        NewsSpace.s5,
        0,
        NewsSpace.s5,
        NewsSpace.s5 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: NewsMotion.base,
          child: KeyedSubtree(key: ValueKey(_step), child: body),
        ),
      ),
    );
  }
}

class _Method extends StatelessWidget {
  const _Method({
    required this.icon,
    required this.title,
    required this.hint,
    required this.on,
    required this.onTap,
  });
  final NewsIconData icon;
  final String title, hint;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NewsRadius.md),
        child: AnimatedContainer(
          duration: NewsMotion.fast,
          padding: const EdgeInsets.all(NewsSpace.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NewsRadius.md),
            border: Border.all(color: on ? c.textPrimary : c.border, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? c.brandSoft : c.surfaceSunken,
                ),
                child: Center(child: NewsIcon(icon, color: on ? c.brandText : c.textPrimary)),
              ),
              const SizedBox(width: NewsSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.type.label.copyWith(fontWeight: FontWeight.w600)),
                    Text(hint, style: context.type.caption.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: on ? c.textPrimary : c.borderStrong, width: on ? 6 : 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone, waiting for its PIN: rings go out from it.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.icon});
  final NewsIconData icon;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _ring = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: 150,
      child: AnimatedBuilder(
        animation: _ring,
        builder: (_, child) => Stack(
          alignment: Alignment.center,
          children: [
            if (!still)
              for (final shift in const [0.0, 0.5])
                Builder(
                  builder: (_) {
                    final t = (_ring.value + shift) % 1;
                    return Opacity(
                      opacity: (1 - t) * 0.7,
                      child: Container(
                        width: 96 + 54 * t,
                        height: 96 + 54 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.brand, width: 2),
                        ),
                      ),
                    );
                  },
                ),
            child!,
          ],
        ),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.brandSoft),
          child: Center(child: NewsIcon(widget.icon, size: 40, color: c.brandText)),
        ),
      ),
    );
  }
}

/// While the plans come: their shape, so nothing moves when they arrive.
class _PlansBones extends StatelessWidget {
  const _PlansBones();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(NewsSpace.s5),
    children: [
      const Center(child: Bone(width: 52, height: 52, radius: 26)),
      const SizedBox(height: NewsSpace.s4),
      const Center(child: Bone(width: 220, height: 32)),
      const SizedBox(height: NewsSpace.s6),
      for (var i = 0; i < 3; i++) ...[
        const Bone(width: double.infinity, height: 260, radius: NewsRadius.lg),
        const SizedBox(height: NewsSpace.s5),
      ],
    ],
  );
}

/// A small turning arrow while a payment is confirmed: the screen around it stays as it is.
class Turning extends StatefulWidget {
  const Turning({super.key, this.size = 16});
  final double size;

  @override
  State<Turning> createState() => _TurningState();
}

class _TurningState extends State<Turning> with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = NewsIcon(
      NewsIcons.refreshCw,
      size: widget.size,
      color: context.colors.textSecondary,
    );
    return context.still ? icon : RotationTransition(turns: _turn, child: icon);
  }
}
