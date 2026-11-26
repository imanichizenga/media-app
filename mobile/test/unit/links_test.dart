import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/app/links.dart';

import '../support/fake_api.dart';

void main() {
  const cases = <String, Place>{
    '/': TabPlace('/'),
    '/en': TabPlace('/'),
    '/video': TabPlace('/video'),
    '/shorts': TabPlace('/video'),
    '/search': TabPlace('/search'),
    '/saved': TabPlace('/saved'),
    '/profile': TabPlace('/profile'),
    '/latest': TabPlace('/'),
    '/biashara': ListPlace('category', 'sw', 'biashara'),
    '/en/business': ListPlace('category', 'en', 'business'),
    '/tag/ajira': ListPlace('tag', 'sw', 'ajira'),
    '/en/story/elections': ListPlace('story', 'en', 'elections'),
    '/author/asha': ListPlace('author', 'sw', 'asha'),
    '/siasa/kichwa-cha-habari': ArticlePlace('sw', 'siasa', 'kichwa-cha-habari'),
    '/en/politics/headline': ArticlePlace('en', 'politics', 'headline'),
    '/en/politics/headline?utm=x#y': ArticlePlace('en', 'politics', 'headline'),
  };
  cases.forEach((path, place) => test(path, () => expect(parsePlace(path), place)));

  for (final path in [
    '/privacy',
    '/en/terms',
    '/api/v1/x',
    '/media/x/y',
    '/a/b/c',
    '/tag',
    '/theme/x.css',
  ]) {
    test('$path is the website\'s', () => expect(parsePlace(path), isA<OutsidePlace>()));
  }
  test('every address the API gives is understood', () {
    for (final locale in ['sw', 'en']) {
      final d = FakeApi.data(locale);
      for (final card in d['latest'] as List<dynamic>) {
        final place = parsePlace((card as Map)['path'] as String);
        expect(place, isA<ArticlePlace>());
        expect((place as ArticlePlace).slug, card['slug']);
        expect(place.locale, locale);
      }
      for (final item in d['navigation'] as List<dynamic>) {
        expect(
          parsePlace((item as Map)['path'] as String),
          ListPlace('category', locale, item['slug'] as String),
        );
      }
    }
  });
}
