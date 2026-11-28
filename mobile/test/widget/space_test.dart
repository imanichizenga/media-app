import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/features/article/article_screen.dart';
import 'package:news_app/features/home/front.dart';
import 'package:news_app/ui/adaptive/adaptive.dart';
import 'package:news_app/ui/components/cards.dart';
import 'package:news_app/ui/components/signals.dart';

import '../support/harness.dart';

const small = Size(360, 640);
final both = const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});

/// As long as headlines get, in Swahili.
const long =
    'Wakulima wa Nyanda za Juu Kusini waiomba serikali kuharakisha ujenzi wa maghala ya mahindi';

/// Changes the feed for one test and puts it back.
Map<String, dynamic> home(String locale, void Function(Map<String, dynamic> home) change) {
  final copy = jsonDecode(jsonEncode(FakeApi.data(locale)['home'])) as Map<String, dynamic>;
  change(copy);
  return copy;
}

Map<String, dynamic> lead(Map<String, dynamic> h) => ((h['lead'] as List).firstWhere(
  (x) => (h['breaking'] as List).every((b) => (b as Map)['id'] != (x as Map)['id']),
) as Map<String, dynamic>);

void main() {
  setUpAll(loadFonts);

  // S1, with everything there can be above it: breaking news and live coverage.
  for (final locale in ['sw', 'en']) {
    for (final (name, size) in [('360x640', small), ('390x844', phone)]) {
      for (final headline in [null, long]) {
        testWidgets(
          'the lead is read whole on $name in $locale${headline == null ? '' : ', a long one'}',
          variant: both,
          (t) async {
            late String words;
            final api = FakeApi()
              ..replies['/api/v1/content/home'] = home(locale, (h) {
                final l = lead(h);
                if (headline != null) l['headline'] = headline;
                words = l['headline'] as String;
                expect(h['breaking'], isNotEmpty);
                expect(h['live'], isNotEmpty);
              });
            await start(
              t,
              size: size,
              locale: locale,
              api: api,
              padding: size == small
                  ? const EdgeInsets.only(top: 24, bottom: 24)
                  : const EdgeInsets.only(top: 47, bottom: 34),
            );
            final bar = t.getRect(find.byType(PlacesBar));
            final cover = find.byType(CoverCard).first;
            final text = find.descendant(of: cover, matching: find.text(words));
            expect(t.renderObject<RenderParagraph>(text).didExceedMaxLines, isFalse);
            expect(t.getRect(text).bottom, lessThanOrEqualTo(bar.top));
            final meta = find.descendant(of: cover, matching: find.byType(Kicker));
            expect(t.getRect(meta).bottom, lessThanOrEqualTo(bar.top));
            expect(t.getRect(meta).top, greaterThan(t.getRect(find.byType(LiveRail)).bottom - 1));
            if (size == phone) {
              final next = find.bySemanticsLabel(RegExp(r'^1\. '));
              expect(t.getRect(next.first).top, lessThan(bar.top - 24));
            }
          },
        );
      }
    }
  }

  testWidgets('what stands above the news is as low as it may be', (t) async {
    await start(t);
    expect(t.getSize(find.byType(BreakingBanner)).height, lessThanOrEqualTo(48));
    expect(t.getSize(find.byType(LiveRail)).height, lessThanOrEqualTo(LiveRail.extent));
    expect(t.getSize(find.byType(TabBar)).height, lessThanOrEqualTo(48));
    expect(find.text('Jumanne, 24 Novemba'), findsNothing);
  });

  testWidgets('nothing live: the day\'s stories, with no LIVE mark', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/content/home'] = home('sw', (h) => h['live'] = <Object>[]);
    await start(t, api: api);
    expect(find.byType(StoryRing), findsWidgets);
    expect(find.text('MUBASHARA'), findsNothing);
  });

  testWidgets('nothing live and no stories: no rail', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/content/home'] = home('sw', (h) {
        h['live'] = <Object>[];
        for (final c in [...h['lead'] as List, ...h['latest'] as List]) {
          (c as Map<String, dynamic>)['image'] = null;
        }
      });
    await start(t, api: api);
    expect(find.byType(StoryRing), findsNothing);
    expect(t.getRect(find.byType(CoverCard)).top, t.getRect(find.byType(BreakingBanner)).bottom);
  });

  testWidgets('an article says what it is in its first screen', variant: both, (t) async {
    final p = await start(t);
    final article = FakeApi.data('sw')['article'] as Map<String, dynamic>;
    await p.push(article['path'] as String);
    final bar = t.getRect(find.byType(ActionBar));
    for (final words in ['headline', 'standfirst']) {
      final text = find.descendant(
        of: find.byType(ArticleHead),
        matching: find.text(article[words] as String),
      );
      expect(t.getRect(text).bottom, lessThanOrEqualTo(bar.top), reason: words);
    }
    final who = find.textContaining('kusoma').last;
    expect(t.getRect(who).bottom, lessThanOrEqualTo(bar.top));
    final head = t.getRect(find.byType(ArticleHead)).top;
    expect(head, lessThanOrEqualTo(844 * 0.4 + 1));
  });

  // S3: what can be seen of any text never lies under the actions, wherever one stops.
  for (final file in Directory(
    '../support/docs/content-fixtures/valid',
  ).listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    testWidgets('the actions cover nothing: $name', (t) async {
      final article = {
        ...FakeApi.data('sw')['article'] as Map<String, dynamic>,
        'body': jsonDecode(file.readAsStringSync()),
      };
      final slug = (article['path'] as String).split('/').last;
      final api = FakeApi()..replies['/api/v1/content/articles/$slug'] = article;
      final p = await start(t, api: api, photographs: false, dpr: 1);
      await p.push(article['path'] as String);
      void check() {
        final view = t.getRect(find.byType(CustomScrollView).last);
        final bar = t.getRect(find.byType(ActionBar));
        expect(bar.intersect(view).height, lessThanOrEqualTo(0));
        for (final e
            in find
                .descendant(of: find.byType(ArticleScreen), matching: find.byType(RichText))
                .evaluate()) {
          if (find
              .ancestor(
                of: find.byElementPredicate((x) => x == e),
                matching: find.byType(ActionBar),
              )
              .evaluate()
              .isNotEmpty) {
            continue;
          }
          final box = e.renderObject! as RenderBox;
          if (!box.hasSize) continue;
          final seen = (box.localToGlobal(Offset.zero) & box.size).intersect(view);
          if (seen.width <= 0 || seen.height <= 0) continue;
          expect(seen.overlaps(bar), isFalse);
        }
      }

      check();
      final list = find.byType(CustomScrollView).last;
      await t.drag(list, const Offset(0, -300));
      await p.settle(1);
      check();
      await t.drag(list, const Offset(0, 120));
      await p.settle(1);
      expect(t.getSize(find.byType(ActionBar)).height, greaterThan(50), reason: 'looking up');
      check();
      await t.drag(list, const Offset(0, -60000));
      await p.settle(1);
      expect(t.getSize(find.byType(ActionBar)).height, greaterThan(50), reason: 'at the end');
      check();
    });
  }

  testWidgets('reading down, the actions step aside', (t) async {
    final p = await start(t);
    await p.push((FakeApi.data('sw')['article'] as Map)['path'] as String);
    await t.drag(find.byType(CustomScrollView).last, const Offset(0, -250));
    await p.settle(2);
    expect(t.getSize(find.byType(ActionBar)).height, 0);
  });

  // S4 and R2: one line, nothing in it cut. The category is said whole (or as its editor's short name), then the
  // time, then the reading time; the reading time gives way first, then the name shortens, then the time goes.
  const longName = 'Uwekezaji, viwanda na biashara za kimataifa';
  const shortName = 'Uwekezaji';
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('meta is one line at $width, text ×$scale, and no category is cut', (t) async {
        final api = FakeApi()
          ..replies['/api/v1/content/home'] = home('sw', (h) {
            for (final list in ['lead', 'latest', 'videos']) {
              for (final x in h[list] as List) {
                final story = x as Map<String, dynamic>;
                story['category'] = {
                  ...story['category'] as Map<String, dynamic>,
                  'name': longName,
                  'short_name': shortName,
                };
                story['breaking_until'] = null;
                story['reading_minutes'] = 12;
              }
            }
          });
        final p = await start(t, size: Size(width, 844), textScale: scale, api: api);
        var seen = 0;
        final said = <String>{};
        for (var i = 0; i < 5; i++) {
          for (final e in find.byType(Kicker).evaluate()) {
            final meta = find.descendant(
              of: find.byElementPredicate((x) => x == e),
              matching: find.byType(MetaLine),
            );
            if (meta.evaluate().isEmpty) continue;
            final texts = find
                .descendant(of: meta, matching: find.byType(RichText))
                .evaluate()
                .map((r) => r.renderObject! as RenderParagraph)
                .toList();
            final whole = texts.map((b) => b.text.toPlainText()).join(' ');
            for (final box in texts) {
              final lines = box.getBoxesForSelection(
                TextSelection(baseOffset: 0, extentOffset: box.text.toPlainText().length),
              );
              expect(lines.map((b) => b.top.round()).toSet().length, lessThanOrEqualTo(1));
              expect(box.didExceedMaxLines, isFalse, reason: whole);
            }
            expect(whole, isNot(contains('…')), reason: 'nothing is cut: $whole');
            final label = texts.first.text.toPlainText().replaceAll('  ·', '');
            if (label != 'MUBASHARA' && label != 'LIVE') {
              expect([longName, shortName], contains(label), reason: 'the category, whole: $whole');
            }
            final time = RegExp(r'\d').hasMatch(whole);
            final reading = whole.contains('kusoma');
            if (reading) expect(label, longName, reason: 'reading time only beside the whole name');
            if (!time) {
              expect(label, shortName, reason: 'the time goes only after the name shortens');
            }
            said.add(
              reading ? 'all' : (label == longName ? 'name+time' : (time ? 'short+time' : 'short')),
            );
            seen++;
          }
          await t.drag(find.byType(CustomScrollView).first, const Offset(0, -600));
          await p.settle(1);
        }
        expect(seen, greaterThan(5));
        if (width == 320 && scale == 2.0) expect(said, isNot(contains('all')));
        if (width == 390 && scale == 1.0) expect(said, contains('short+time'));
        expect(t.takeException(), isNull);
      });
    }
  }

  // V2
  for (final news in [true, false]) {
    testWidgets('what arrives with the stories arrives in one frame, breaking: $news', (t) async {
      final api = FakeApi()
        ..replies['/api/v1/content/home'] = home('sw', (h) {
          if (!news) {
            h['breaking'] = <Object>[];
            h['live'] = <Object>[];
            for (final x in h['lead'] as List) {
              (x as Map)['breaking_until'] = null;
            }
          }
        })
        ..silent = true;
      final p = await start(t, api: api, settle: false);
      await p.settle(3);
      final bones = t.getRect(find.byType(CoverCard));
      final tabs = t.getRect(find.byType(TabBar));
      await p.stop();
      final q = await start(
        t,
        api: FakeApi()..replies['/api/v1/content/home'] = api.replies['/api/v1/content/home']!,
        settle: false,
      );
      // Frame by frame: the stories are never seen without what stands above them.
      var first = true;
      for (var i = 0; i < 40; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
        await t.pump(const Duration(milliseconds: 16));
        final cover = find.byType(CoverCard);
        if (cover.evaluate().isEmpty || t.widget<CoverCard>(cover.first).story == null) continue;
        final at = t.getRect(cover.first);
        if (!first) continue;
        first = false;
        if (news) {
          expect(find.byType(BreakingBanner), findsOneWidget);
          expect(t.getSize(find.byType(LiveRail)).height, LiveRail.extent);
        } else {
          expect(find.byType(BreakingBanner), findsNothing);
          expect((at.top - bones.top).abs(), lessThanOrEqualTo(8));
          expect((at.height - bones.height).abs(), lessThanOrEqualTo(8));
        }
        expect((t.getRect(find.byType(TabBar)).top - tabs.top).abs(), lessThanOrEqualTo(8));
      }
      expect(first, isFalse);
      await q.settle(4);
      final end = t.getRect(find.byType(CoverCard).first);
      // The rail has its room in the skeleton already: only breaking news comes in above.
      final above = news ? 48 : 0;
      expect((end.top - bones.top - above).abs(), lessThanOrEqualTo(8));
    });
  }

  testWidgets('later news waits for a reader who is further down', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/content/home'] = home('sw', (h) {
        h['breaking'] = <Object>[];
        for (final x in h['lead'] as List) {
          (x as Map)['breaking_until'] = null;
        }
      });
    final p = await start(t, api: api);
    expect(find.byType(BreakingBanner), findsNothing);
    final list = find.byType(CustomScrollView).first;
    await t.drag(list, const Offset(0, -500));
    await p.settle(2);
    final mark = t.getRect(find.text('Habari kuu')).top;
    api.replies.remove('/api/v1/content/home');
    await t.runAsync(() => p.refreshHome());
    await p.settle(2);
    expect(t.getRect(find.text('Habari kuu')).top, mark, reason: 'nothing moved');
    expect(find.text('Kuna habari mpya'), findsOneWidget);
    await t.tap(find.text('Kuna habari mpya'));
    await p.settle(4);
    expect(find.text('Kuna habari mpya'), findsNothing);
    expect(find.byType(BreakingBanner), findsOneWidget);
    expect(find.byType(FrontPage), findsOneWidget);
  });

  testWidgets('at the top, later news grows in', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/content/home'] = home('sw', (h) {
        h['breaking'] = <Object>[];
      });
    final p = await start(t, api: api);
    expect(find.byType(BreakingBanner), findsNothing);
    api.replies.remove('/api/v1/content/home');
    await t.runAsync(() => p.refreshHome());
    await p.settle(3);
    expect(find.byType(BreakingBanner), findsOneWidget);
    expect(find.text('Kuna habari mpya'), findsNothing);
  });

  // S5
  testWidgets('a wide screen is used: the lead has the latest beside it, sections three across', (
    t,
  ) async {
    await start(t, size: tablet);
    final cover = t.getRect(find.byType(CoverCard).first);
    final latest = t.getRect(
      find.descendant(of: find.byType(FrontPage), matching: find.text('Habari mpya')).first,
    );
    expect(latest.left, greaterThan(cover.right));
    expect(latest.top, lessThan(cover.bottom));
  });
}
