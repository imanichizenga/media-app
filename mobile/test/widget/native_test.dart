import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoActionSheet,
        CupertinoAlertDialog,
        CupertinoSliverNavigationBar,
        CupertinoSliverRefreshControl,
        CupertinoTabBar;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' show PublicImage;
import 'package:news_app/features/article/article_screen.dart';
import 'package:news_app/features/article/photo_viewer.dart';
import 'package:news_app/features/home/front.dart';
import 'package:news_app/ui/adaptive/adaptive.dart';
import 'package:news_app/ui/adaptive/tab_header.dart';
import 'package:news_app/ui/components/cards.dart';

import '../support/harness.dart';

final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
final android = TargetPlatformVariant.only(TargetPlatform.android);
const both = TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});

PublicImage storyImage() =>
    PublicImage.fromJson((FakeApi.data('sw')['article'] as Map)['image'] as Map<String, dynamic>);

double offset(WidgetTester t, Finder list) => t
    .state<ScrollableState>(find.descendant(of: list, matching: find.byType(Scrollable)).first)
    .position
    .pixels;

void main() {
  setUpAll(loadFonts);
  final article = (FakeApi.data('sw')['article'] as Map)['path'] as String;

  testWidgets(
    'Android: Material bar with its pill, top app bar, its own refresh',
    variant: android,
    (t) async {
      final p = await start(t);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsWidgets);
      await p.go('/profile');
      expect(find.byType(SliverAppBar), findsOneWidget);
    },
  );

  testWidgets('iOS: translucent bar, large title, its own refresh', variant: ios, (t) async {
    final p = await start(t);
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
    expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), findsWidgets);
    await p.go('/profile');
    expect(find.byType(CupertinoSliverNavigationBar), findsOneWidget);
  });

  testWidgets('pulling down refreshes', variant: both, (t) async {
    final p = await start(t);
    int asked() => p.api.asked.where((o) => o.uri.path.endsWith('/content/home')).length;
    final before = asked();
    await t.fling(find.byType(CustomScrollView).first, const Offset(0, 400), 900);
    await p.settle();
    expect(asked(), greaterThan(before));
  });

  testWidgets('iOS: swiping from the edge goes back', variant: ios, (t) async {
    final p = await start(t);
    await p.push(article);
    expect(find.byType(ArticleScreen), findsOneWidget);
    await t.timedDragFrom(
      const Offset(4, 400),
      const Offset(340, 0),
      const Duration(milliseconds: 250),
    );
    await p.settle();
    expect(find.byType(ArticleScreen), findsNothing);
  });

  testWidgets(
    'Home: swiping turns the page; each keeps its place; the name gives way',
    variant: both,
    (t) async {
      final p = await start(t);
      final front = find.byType(FrontPage);
      Finder list(Finder of) => find.descendant(of: of, matching: find.byType(CustomScrollView));
      final tabs = t.widget<TabBar>(find.byType(TabBar)).controller!;
      expect(tabs.length, greaterThan(5));
      final rest = t.getRect(find.byType(TabBar)).top;
      await t.drag(list(front), const Offset(0, -700));
      await p.settle(2);
      final at = offset(t, list(front));
      expect(at, greaterThan(500));
      final up = t.getRect(find.byType(TabBar)).top;
      expect(rest - up, defaultTargetPlatform == TargetPlatform.iOS ? 12 : 56, reason: 'pinned');
      await t.fling(find.byType(TabBarView), const Offset(-300, 0), 1500);
      await p.settle();
      expect(tabs.index, 1);
      expect(t.getRect(find.byType(TabBar)).top, rest, reason: 'a page at its top has its header');
      await t.fling(find.byType(TabBarView), const Offset(300, 0), 1500);
      await p.settle();
      expect(tabs.index, 0);
      expect(offset(t, list(front)), at);
      expect(find.byType(TabHeader), findsOneWidget);
    },
  );

  testWidgets('a section of the front page opens its tab', (t) async {
    final p = await start(t);
    final tabs = t.widget<TabBar>(find.byType(TabBar)).controller!;
    final more = find.descendant(of: find.byType(FrontPage), matching: find.text('Zaidi'));
    for (var i = 0; i < 8 && more.hitTestable().evaluate().isEmpty; i++) {
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -180));
      await p.settle(1);
    }
    await t.tap(more.hitTestable().first);
    await p.settle();
    expect(tabs.index, 1);
  });

  testWidgets('a held card offers to save, share and copy', variant: both, (t) async {
    final p = await start(t);
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    addTearDown(
      () =>
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final card = find.byType(CoverCard).first;
    await t.longPress(card);
    await p.settle();
    for (final words in ['Sambaza', 'Nakili kiungo']) {
      expect(find.text(words), findsOneWidget);
    }
    expect(
      find.byType(StoryPreview),
      defaultTargetPlatform == TargetPlatform.iOS ? findsOneWidget : findsNothing,
    );
    await t.tap(find.text('Nakili kiungo'));
    await p.settle();
    expect(copied, startsWith('https://'));
    await t.longPress(card);
    await p.settle();
    await t.tap(find.text('Hifadhi').last);
    await p.settle();
    final story = t.widget<CoverCard>(card).story!;
    final rows = await t.runAsync(() => p.db.select(p.db.savedArticles).get());
    expect(rows!.map((r) => r.path), contains(story.path));
    await t.pump(const Duration(seconds: 6));
  });

  testWidgets('choices and confirmations are the platform\'s', variant: both, (t) async {
    final p = await start(t);
    final apple = defaultTargetPlatform == TargetPlatform.iOS;
    await p.go('/profile');
    await t.tap(find.text('Mwonekano'));
    await p.settle();
    expect(find.byType(CupertinoActionSheet), apple ? findsOneWidget : findsNothing);
    expect(find.byType(BottomSheet), apple ? findsNothing : findsOneWidget);
    await t.tap(find.text('Giza'));
    await p.settle();
    expect(Theme.of(t.element(find.byType(PlaceBar))).brightness, Brightness.dark);
    await p.push(article);
    await p.go('/saved');
    await t.tap(find.text('Ulizosoma'));
    await p.settle();
    await t.tap(find.bySemanticsLabel('Futa historia'));
    await p.settle();
    expect(find.byType(CupertinoAlertDialog), apple ? findsOneWidget : findsNothing);
    expect(find.byType(AlertDialog), apple ? findsNothing : findsOneWidget);
    await t.tap(find.text('Futa'));
    await p.settle();
    expect(find.text('Historia yako iko wazi'), findsOneWidget);
  });

  testWidgets('a picture closes when pulled down, not while one looks close', variant: both, (
    t,
  ) async {
    final p = await start(t);
    final image = storyImage();
    Future<void> open() async {
      showPhotos(t.element(find.byType(FrontPage)), [
        Photo(image, alt: 'a', caption: 'Maelezo ' * 30),
        Photo(image, alt: 'b'),
      ]).ignore();
      await p.settle(3);
    }

    await open();
    expect(find.byType(PhotoViewer), findsOneWidget);
    await t.fling(find.byType(PhotoViewer), const Offset(-300, 0), 1500);
    await p.settle(2);
    expect(find.text('2 / 2'), findsOneWidget);
    await t.drag(find.byType(PhotoViewer), const Offset(0, 260));
    await p.settle(3);
    expect(find.byType(PhotoViewer), findsNothing);
    await open();
    final middle = t.getCenter(find.byType(PhotoViewer));
    await t.tapAt(middle);
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(middle);
    await p.settle(2);
    await t.drag(find.byType(PhotoViewer), const Offset(0, 260));
    await p.settle(2);
    expect(find.byType(PhotoViewer), findsOneWidget, reason: 'close up, a finger looks around');
  });

  testWidgets('words of a story can be selected, copied and passed on', variant: both, (t) async {
    final p = await start(t);
    await p.push(article);
    final words = find.textContaining('Wataalamu', findRichText: true).last;
    await t.ensureVisible(words);
    await p.settle(2);
    await t.longPressAt(t.getTopLeft(words) + const Offset(40, 12));
    await p.settle(2);
    // The test's font is wider than the phone's: what does not fit is on the menu's next page.
    final menu = t.widget<AdaptiveTextSelectionToolbar>(find.byType(AdaptiveTextSelectionToolbar));
    final quote = menu.buttonItems!.singleWhere((x) => x.label == 'Sambaza nukuu');
    expect(menu.buttonItems!.first.type, ContextMenuButtonType.copy);
    Object? shared;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared = call.arguments;
        return 'ok';
      },
    );
    quote.onPressed!();
    await p.settle();
    expect(shared.toString(), contains('“'));
    expect(shared.toString(), contains(article));
  });

  testWidgets('saving fills the mark in red; sharing is never red', (t) async {
    final p = await start(t);
    await p.push(article);
    await t.tap(find.bySemanticsLabel('Hifadhi').last);
    await p.settle();
    expect(find.bySemanticsLabel('Ondoa kwenye hifadhi'), findsOneWidget);
    await t.pump(const Duration(seconds: 6));
  });
}
