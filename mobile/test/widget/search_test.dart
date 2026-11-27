import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/features/article/article_screen.dart';
import 'package:news_app/features/explore/search.dart';
import 'package:news_app/ui/components/cards.dart';

import '../support/harness.dart';

/// Search in the app (ADR-0049): headlines while typing, results with filters on the search key, recent searches
/// kept on the phone.
void main() {
  setUpAll(loadFonts);
  const both = TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS});
  final data = FakeApi.data('en');
  final card = (data['latest'] as List<dynamic>).first as Map<String, dynamic>;
  final article = data['article'] as Map<String, dynamic>;

  Map<String, dynamic> answer({List<Object> hits = const [], bool available = true}) => {
    'available': available,
    'query': 'mbeya',
    'total': hits.length,
    'total_is_exact': true,
    'engine': 'opensearch',
    'next_cursor': null,
    'results': hits,
  };

  final hit = {
    'card': card,
    'snippet': [
      {'text': 'A short film from ', 'hit': false},
      {'text': 'Mbeya', 'hit': true},
      {'text': ' wins.', 'hit': false},
    ],
  };

  FakeApi searching() => FakeApi()
    ..replies.addAll({
      '/api/v1/content/search': answer(hits: [hit]),
      '/api/v1/content/search/suggest': {
        'query': 'mb',
        'results': [
          {
            'headline': article['headline'],
            'path': article['path'],
            'type': 'article',
            'category': 'Culture',
          },
        ],
      },
    });

  Iterable<RequestOptions> asked(FakeApi api, String end) =>
      api.asked.where((o) => o.uri.path.endsWith(end));

  testWidgets('typing shows headlines, and one opens its story', variant: both, (t) async {
    final api = searching();
    final p = await start(t, api: api, locale: 'en');
    await p.go('/search');
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), 'm');
    await p.settle(2);
    expect(asked(api, '/suggest'), isEmpty, reason: 'one letter asks nothing');
    await t.enterText(find.byType(EditableText), 'mb');
    await p.settle();
    expect(asked(api, '/suggest').single.uri.queryParameters, {'q': 'mb', 'locale': 'en'});
    await t.tap(find.text(article['headline'] as String));
    await p.settle();
    expect(find.byType(ArticleScreen), findsOneWidget);
  });

  testWidgets('the search key shows results with what matched, and keeps the words', variant: both, (
    t,
  ) async {
    final api = searching();
    final p = await start(t, api: api, locale: 'en');
    await p.go('/search');
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), ' mbeya ');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await p.settle();
    expect(asked(api, '/content/search').single.uri.queryParameters, {
      'q': 'mbeya',
      'locale': 'en',
      'sort': 'relevance',
    });
    expect(find.text('1 stories found'), findsOneWidget);
    expect(find.byType(RowCard), findsOneWidget);
    final snippet = t.widget<Snippet>(find.byType(Snippet));
    expect(snippet.parts.where((s) => s.hit).single.text, 'Mbeya');

    // Back to an empty field: the words are among the recent searches, and picking them asks again.
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), '');
    await p.settle();
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('mbeya'), findsOneWidget);
    expect(await p.db.allPrefs(), containsPair('recentSearches', '["mbeya"]'));
  });

  testWidgets('a filter asks again with the types of its kind', (t) async {
    final api = searching();
    final p = await start(t, api: api, locale: 'en');
    await p.go('/search');
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), 'mbeya');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await p.settle();
    await t.tap(find.bySemanticsLabel('Type: All'));
    await p.settle();
    await t.tap(find.widgetWithText(CheckedPopupMenuItem<SearchKind>, 'Videos'));
    await p.settle();
    expect(asked(api, '/content/search').last.uri.queryParameters['type'], 'video,youtube,short');
  });

  testWidgets('nothing found says so; a search that is down says that', (t) async {
    final api = searching()..replies['/api/v1/content/search'] = answer();
    final p = await start(t, api: api, locale: 'en');
    await p.go('/search');
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), 'zzzz');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await p.settle();
    expect(find.text('No stories match'), findsOneWidget);

    api.replies['/api/v1/content/search'] = answer(available: false);
    await t.tap(find.byType(EditableText));
    await t.enterText(find.byType(EditableText), 'yyyy');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await p.settle();
    expect(find.text('Search is not available right now. Try again in a moment.'), findsOneWidget);
  });
}
