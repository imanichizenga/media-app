import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_app/core/network/failures.dart';
import 'package:news_app/core/network/interceptors.dart';
import 'package:news_app/core/network/loaded.dart';
import 'package:news_app/core/storage/database.dart';

import '../support/fake_api.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;
  late Dio dio;
  late ContentApi content;
  Future<Response<Home>> home(Map<String, dynamic> x) => content.home(extra: x);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = api;
    dio.interceptors.addAll([
      CacheInterceptor(db),
      RetryInterceptor(dio, base: const Duration(milliseconds: 1)),
    ]);
    content = ContentApi(dio);
  });
  tearDown(() => db.close());

  test(
    'an answer is kept, served without a network, and asked for again only by its tag',
    () async {
      expect(await fromCache(home), isNull);
      final first = await fromNetwork(home);
      await pumpEventQueue();
      api.offline = true;
      final kept = await fromCache(home);
      expect(kept!.value.lead.length, first.value.lead.length);
      api.offline = false;
      final again = await content.home();
      expect(again.extra['unchanged'], isTrue);
      expect(again.data!.lead.length, first.value.lead.length);
      expect(api.asked.last.headers['If-None-Match'], isNotNull);
    },
  );

  test('a kind of story from the future is left out, the rest is shown', () async {
    final list = jsonDecode(jsonEncode(FakeApi.data('sw')['latest'])) as List<dynamic>;
    (list[1] as Map)['type'] = 'hologram';
    api.replies['/api/v1/content/latest'] = FakeApi.page(list);
    final page = await content.latest();
    expect(page.data!.results.length, list.length - 1);
  });

  test('a kept answer in an older shape counts as nothing kept', () async {
    await db.store('/api/v1/content/home?locale=sw', '', '{"lead": "what"}');
    expect(await fromCache(home), isNull);
  });

  test('reads are tried again, at most twice more', () async {
    api.replies['/api/v1/content/home'] = 503;
    await expectLater(fromNetwork(home), throwsA(isA<ServerFailure>()));
    expect(api.asked.length, 3);
    api.asked.clear();
    api.replies['/api/v1/content/home'] = 404;
    await expectLater(fromNetwork(home), throwsA(isA<NotFoundFailure>()));
    expect(api.asked.length, 1);
    api.asked.clear();
    api.offline = true;
    await expectLater(fromNetwork(home), throwsA(isA<OfflineFailure>()));
    expect(api.asked.length, 3);
  });

  test('writes are never tried again', () async {
    api.replies['/x'] = 503;
    await expectLater(dio.post<void>('/x'), throwsA(isA<DioException>()));
    expect(api.asked.length, 1);
  });

  test('old and excess entries go, oldest first; saved articles stay', () async {
    for (var i = 0; i < 5; i++) {
      await db.store('k$i', '', 'x' * 100);
      await db.customStatement('UPDATE cache_entries SET used_at = used_at - ? WHERE key = ?', [
        (10 - i) * 100,
        'k$i',
      ]);
    }
    await db.putSaved(
      SavedArticlesCompanion.insert(path: '/a', card: '{}', savedAt: DateTime(2020)),
    );
    expect(await db.evict(maxBytes: 250, maxAge: const Duration(days: 30)), 3);
    expect(await db.cached('k4'), isNotNull);
    expect(await db.cached('k0'), isNull);
    expect(await db.saved('/a'), isNotNull);
  });

  test('history keeps the newest, and progress only grows', () async {
    for (var i = 0; i < AppDatabase.historyLimit + 5; i++) {
      await db.opened('/p$i', '{}');
    }
    final rows = await db.watchHistory().first;
    expect(rows.length, AppDatabase.historyLimit);
    await db.readTo(rows.first.path, 75);
    await db.readTo(rows.first.path, 25);
    expect(
      (await db.watchHistory().first).firstWhere((r) => r.path == rows.first.path).percent,
      75,
    );
  });

  test('a device id is a random UUID', () {
    final a = const Uuidish().v4();
    expect(
      a,
      matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
    );
    expect(a, isNot(const Uuidish().v4()));
  });

  test('large answers are decoded', () async {
    final big = jsonEncode(List.generate(20000, (i) => {'i': i}));
    expect(big.length, greaterThan(60 * 1024));
    expect((await decodeJson(big))! as List<dynamic>, hasLength(20000));
    expect(compute, isNotNull);
  });
}
