import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/core/config/theme_choice.dart';
import 'package:news_app/core/storage/prefs.dart';
import 'package:news_app/features/explore/explore_screen.dart';
import 'package:news_app/ui/adaptive/adaptive.dart';
import 'package:news_app/ui/adaptive/tab_header.dart';
import 'package:news_app/ui/components/cards.dart';
import 'package:news_app/ui/components/picture.dart';
import 'package:news_app/ui/components/signals.dart';
import 'package:news_app/ui/tokens/news_icon.dart';
import 'package:news_app/ui/tokens/news_icons.g.dart';
import 'package:news_app/ui/tokens/theme.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../support/harness.dart';

/// M3.2: what G2 asked for after M3.1 (R1 to R5), each held by a test.
void main() {
  setUpAll(loadFonts);
  const both = TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});

  // R1. A play mark in the middle of a picture is the player's alone; a card says how long, in a corner.
  testWidgets('no card in any list shows a play button', variant: both, (t) async {
    final p = await start(t, photographs: false);
    Future<void> check(String where) async {
      for (var i = 0; i < 4; i++) {
        final marks = find.byWidgetPredicate((w) => w is NewsIcon && w.icon == NewsIcons.play);
        for (final e in marks.evaluate()) {
          final icon = e.widget as NewsIcon;
          final inBar = find
              .ancestor(of: find.byWidget(icon), matching: find.byType(PlacesBar))
              .evaluate()
              .isNotEmpty;
          if (inBar) continue;
          expect(
            icon.size,
            lessThanOrEqualTo(12),
            reason: '$where: a play mark larger than a badge',
          );
        }
        final list = find.byType(CustomScrollView);
        if (list.evaluate().isEmpty) break;
        await t.drag(list.first, const Offset(0, -500), warnIfMissed: false);
        await p.settle(1);
      }
    }

    await check('home');
    await p.go('/video');
    await t.tap(find.text('Ndefu'));
    await p.settle();
    final lead = find.byType(VideoCard).first;
    expect(
      find.descendant(of: lead, matching: find.textContaining(RegExp(r'^\d+:\d\d$'))),
      findsOneWidget,
      reason: 'the duration stays',
    );
    await check('videos');
    await p.push('/biashara');
    await check('category');
  });

  // R3. The rail: the editor's title, or the headline cut between words; two lines; within 96.
  const longest = [
    'Kinachoendelea Bungeni',
    'Mazishi ya Mzee Kingunge',
    'Uchaguzi Mkuu Zanzibar',
    'Mitihani ya Kidato cha 4',
    'Mashindano ya Kuogelea',
  ];
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('live rail titles at text ×$scale', variant: both, (t) async {
      final home = jsonDecode(jsonEncode(FakeApi.data('sw')['home'])) as Map<String, dynamic>;
      final live = home['live'] as List;
      for (var i = 0; i < live.length; i++) {
        (live[i] as Map<String, dynamic>)['rail_title'] = longest[i % longest.length];
      }
      final api = FakeApi()..replies['/api/v1/content/home'] = home;
      await start(t, api: api, textScale: scale, photographs: false);
      expect(t.getSize(find.byType(LiveRail)).height, lessThanOrEqualTo(LiveRail.extent));
      final labels = find.byType(RailLabel);
      expect(labels, findsWidgets);
      for (final e in labels.evaluate()) {
        final text = (e.widget as RailLabel).text;
        final paragraph = t.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byElementPredicate((x) => x == e),
            matching: find.byType(RichText),
          ),
        );
        expect(paragraph.didExceedMaxLines, isFalse, reason: text);
        // Each line ends where a word ends: the first line's end is a space, or the end of the text.
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler,
          textAlign: TextAlign.center,
        )..layout(maxWidth: paragraph.size.width);
        final end = painter.getLineBoundary(const TextPosition(offset: 0)).end;
        painter.dispose();
        expect(
          end == text.length || text[end] == ' ' || text[end - 1] == ' ',
          isTrue,
          reason: text,
        );
        final box = t.getRect(find.byElementPredicate((x) => x == e));
        expect(box.bottom, lessThanOrEqualTo(t.getRect(find.byType(LiveRail)).bottom + 0.5));
      }
    });
  }

  testWidgets('a live story without a rail title shows its headline cut between words', (t) async {
    await start(t, photographs: false);
    final first = (FakeApi.data('sw')['home'] as Map)['live'][0] as Map;
    final label = t.widget<RailLabel>(find.byType(RailLabel).first);
    expect(label.text, first['rail_title']);
    expect(label.text.length, lessThanOrEqualTo(24));
  });

  // R4. Each section's tile has its own picture.
  testWidgets('no two tiles share a picture', (t) async {
    final p = await start(t);
    await p.go('/search');
    final tiles = t.widgetList<CategoryTile>(find.byType(CategoryTile)).toList();
    expect(tiles.length, greaterThan(4));
    final ids = [for (final x in tiles) x.image?.id].nonNulls.toList();
    expect(ids.length, greaterThan(3));
    expect(ids.toSet().length, ids.length);
  });

  // R5. Android's bar: the brand on its icon and a soft pill; labels in ink; enough contrast in every theme.
  double contrast(Color a, Color b) {
    final (x, y) = (a.computeLuminance(), b.computeLuminance());
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }

  test('the bar of places reads in every theme', () {
    for (final key in themeKeys) {
      for (final scheme in ThemeScheme.values) {
        final c = ThemeChoice(key: key, color: '#b5121b').colors(scheme);
        final roles = AndroidPlaces.of(c);
        final name = '$key ${scheme.name}';
        expect(contrast(roles.label, c.navBg), greaterThanOrEqualTo(4.5), reason: '$name label');
        expect(
          contrast(c.navActive, roles.indicator),
          greaterThanOrEqualTo(3),
          reason: '$name icon',
        );
        expect(roles.label, isNot(c.brand), reason: '$name: ink, not the brand');
        // Quiet Paper's active place is ink already; in the others it is the brand, and its label is not.
        if (c.navActive != c.textPrimary) {
          expect(roles.label, isNot(c.navActive), reason: '$name: the label is not the brand');
        }
      }
    }
  });

  testWidgets('android: the active place is a soft pill under the brand, its label in ink', (
    t,
  ) async {
    await start(t, photographs: false);
    final c = t.element(find.byType(PlacesBar)).colors;
    final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.indicatorColor, c.brandSoft);
    final active = t.widget<Text>(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('Nyumbani')),
    );
    final style = DefaultTextStyle.of(t.element(find.text('Nyumbani'))).style.merge(active.style);
    expect(style.color, c.textPrimary);
  });

  // More sections than the row shows: it says so (a fade and a chevron), and the chevron goes on.
  testWidgets('a row of sections that goes on says so, and the chevron goes on', variant: both, (
    t,
  ) async {
    final p = await start(t, size: const Size(360, 640), photographs: false);
    final row = find.byType(MoreTabs);
    expect(find.bySemanticsLabel('Sehemu za awali'), findsNothing);
    final more = find.descendant(of: row, matching: find.bySemanticsLabel('Sehemu zaidi'));
    expect(more, findsOneWidget);
    expect(t.getSize(more).width, greaterThanOrEqualTo(44));
    final bar = find.descendant(of: row, matching: find.byType(Scrollable)).first;
    final before = t.state<ScrollableState>(bar).position.pixels;
    await t.tap(more);
    await p.settle(2);
    expect(t.state<ScrollableState>(bar).position.pixels, greaterThan(before + 100));
    expect(
      find.descendant(of: row, matching: find.bySemanticsLabel('Sehemu za awali')),
      findsOneWidget,
    );
  });

  testWidgets('a row that fits shows no chevron', (t) async {
    final nav = (FakeApi.data('sw')['navigation'] as List).take(1).toList();
    final api = FakeApi()..replies['/api/v1/content/navigation'] = nav;
    await start(t, size: const Size(1200, 900), api: api, photographs: false);
    expect(find.bySemanticsLabel('Sehemu zaidi'), findsNothing);
    expect(find.bySemanticsLabel('Sehemu za awali'), findsNothing);
  });

  // The red budget: no screen reads as a red screen (public-experience.md, rule 1).
  for (final theme in themeKeys) {
    for (final scheme in [SchemeChoice.light, SchemeChoice.dark]) {
      testWidgets('red budget: $theme ${scheme.name}', variant: both, (t) async {
        final p = await start(
          t,
          dpr: 1,
          photographs: false,
          scheme: scheme,
          theme: ThemeChoice(key: theme, color: '#b5121b'),
        );
        final red = t.element(find.byType(PlacesBar)).colors.brand;
        for (final screen in ['/', '/biashara', '/search', 'article']) {
          if (screen == 'article') {
            await p.push((FakeApi.data('sw')['article'] as Map)['path'] as String);
          } else if (screen != '/') {
            await p.go(screen);
          }
          final share = await t.runAsync(() => redShare(t, red));
          expect(
            share,
            lessThan(redBudget),
            reason: '$screen: ${(share! * 100).toStringAsFixed(1)}% red',
          );
        }
      });
    }
  }
}

/// The most red any screen may show. The largest approved use is Bold Ink's breaking banner on Home, about 5.6%
/// of a 390×844 screen (support/docs/design/public-experience.md, rule 1).
const redBudget = 0.075;

/// How much of the whole screen is the brand's red (within a small distance); pictures are not counted as red.
Future<double> redShare(WidgetTester t, Color red) async {
  final image = await captureImage(find.byType(MaterialApp).evaluate().first);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final pictures = [
    for (final e in find.byType(NewsPicture).evaluate())
      if (e.renderObject case final RenderBox box when box.hasSize && box.attached)
        box.localToGlobal(Offset.zero) & box.size,
  ];
  var counted = 0, reds = 0;
  final (r0, g0, b0) = ((red.r * 255).round(), (red.g * 255).round(), (red.b * 255).round());
  for (var y = 0; y < image.height; y += 2) {
    for (var x = 0; x < image.width; x += 2) {
      final at = Offset(x.toDouble(), y.toDouble());
      counted++;
      if (pictures.any((r) => r.contains(at))) continue;
      final i = (y * image.width + x) * 4;
      final (r, g, b) = (bytes.getUint8(i), bytes.getUint8(i + 1), bytes.getUint8(i + 2));
      if ((r - r0).abs() + (g - g0).abs() + (b - b0).abs() < 60) reds++;
    }
  }
  image.dispose();
  return counted == 0 ? 0 : reds / counted;
}
