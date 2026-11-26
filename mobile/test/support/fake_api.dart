import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// The public API as the demo seed answers it, without a network. Anything can be replaced or made to fail.
class FakeApi implements HttpClientAdapter {
  FakeApi({this.offline = false});

  bool offline;

  /// path → status, or a body.
  final replies = <String, Object>{};
  final asked = <RequestOptions>[];

  /// Never answers: what the skeletons are drawn over.
  bool silent = false;

  /// Holds back the next pages of lists until completed.
  Completer<void>? pages;

  static final _data = <String, Map<String, dynamic>>{};
  static Map<String, dynamic> data(String locale) => _data[locale] ??= _read(locale);

  static Map<String, dynamic> _read(String locale) {
    final d =
        jsonDecode(File('test/fixtures/$locale.json').readAsStringSync()) as Map<String, dynamic>;
    // The seed's breaking story is also its first lead: the banner shows it, as the API would.
    final home = d['home'] as Map<String, dynamic>;
    if ((home['breaking'] as List<dynamic>).isEmpty) {
      home['breaking'] = [(home['lead'] as List<dynamic>).first];
    }
    return d;
  }

  static Map<String, dynamic> config([Map<String, dynamic> over = const {}]) => <String, dynamic>{
    'version': '1.0.0',
    'media_base_url': 'https://media.test',
    'versions': {
      'android': {'minimum': '', 'recommended': '', 'store': ''},
      'ios': {'minimum': '', 'recommended': '', 'store': ''},
    },
    'maintenance': {'on': false, 'sw': '', 'en': ''},
    'flags': {'shorts': true, 'youtube': true, 'offline_saving': true},
    'links': {
      'about': 'https://www.test/about',
      'editorial': 'https://www.test/editorial',
      'corrections': '',
      'contact': 'https://www.test/contact',
      'privacy': 'https://www.test/privacy',
      'terms': 'https://www.test/terms',
    },
    'pinning': {'enabled': false, 'pins': <String>[]},
    'identity': {
      'brand_name': 'Mfano News',
      'tagline_sw': '',
      'tagline_en': '',
      'wordmark_light': null,
      'wordmark_dark': null,
      'symbol': null,
    },
    'theme': <String, dynamic>{
      'schema_version': 1,
      'hash': 'abc',
      'key': 'signature',
      'color': '#b5121b',
      'dark_color': '',
      'css': '/theme/abc.css',
      'theme_color': {'light': '#ffffff', 'dark': '#0f1011'},
      'tokens': {'light': <String, String>{}, 'dark': <String, String>{}},
    },
    'localization': {'default_locale': 'sw', 'timezone': 'Africa/Dar_es_Salaam'},
    ...over,
  };

  static Map<String, dynamic> page(List<dynamic> results, [String? next]) => {
    'results': results,
    'next_cursor': next,
  };

  Object? _answer(RequestOptions o) {
    final path = o.uri.path;
    if (replies[path] case final reply?) return reply;
    final d = data(o.uri.queryParameters['locale'] ?? 'sw');
    if (path.endsWith('/app-config')) return config();
    if (path.endsWith('/content/home')) return d['home'];
    if (path.endsWith('/content/navigation')) return d['navigation'];
    if (path.endsWith('/content/latest')) {
      final cursor = o.uri.queryParameters['cursor'];
      final all = d['latest'] as List<dynamic>;
      return cursor == null ? page(all.take(20).toList(), 'two') : page(all.skip(20).toList());
    }
    if (path.endsWith('/types/short')) return page((d['home'] as Map)['shorts'] as List<dynamic>);
    if (path.endsWith('/types/video')) return page(d['videos'] as List<dynamic>);
    if (path.contains('/content/categories/')) return d['category'];
    if (path.contains('/content/authors/')) {
      return {
        ...page((d['latest'] as List<dynamic>).take(6).toList()),
        'author': {
          ...((d['article'] as Map)['authors'] as List<dynamic>).first as Map<String, dynamic>,
          'bio': 'Anaripoti kuhusu jamii na utamaduni kutoka Mbeya kwa miaka kumi.',
          'expertise': ['Utamaduni', 'Elimu'],
          'links': ['https://example.org/mwandishi'],
        },
      };
    }
    if (path.contains('/related')) return {'results': d['related']};
    if (path.contains('/content/articles/')) {
      final live = d['live'] as Map<String, dynamic>?;
      if (live != null && path.endsWith('/${live['slug']}')) return live;
      return d['article'];
    }
    return null;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    asked.add(options);
    if (silent && !options.uri.path.endsWith('/content/navigation')) await Completer<void>().future;
    if (options.uri.queryParameters.containsKey('cursor')) await pages?.future;
    if (offline) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionError);
    }
    final answer = _answer(options);
    ResponseBody json(Object body, int status, [Map<String, List<String>> headers = const {}]) =>
        ResponseBody.fromString(
          jsonEncode(body),
          status,
          headers: {
            'content-type': ['application/json'],
            ...headers,
          },
        );
    if (answer is int) return json({'code': 'x'}, answer);
    if (answer == null) return json({'code': 'not_found'}, 404);
    final etag = '"${jsonEncode(answer).hashCode}"';
    if (options.headers['If-None-Match'] == etag) return ResponseBody.fromString('', 304);
    return json(answer, 200, {
      'etag': [etag],
    });
  }

  @override
  void close({bool force = false}) {}
}
