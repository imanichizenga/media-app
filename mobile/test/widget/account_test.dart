import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_app/core/account/session.dart';
import 'package:news_app/features/account/engagement.dart';
import 'package:news_app/features/account/sign_in.dart';
import 'package:news_app/ui/components/card_counts.dart';

import '../support/harness.dart';

/// M4 in the app (ADR-0050): one sheet, never a wall, and what was asked is done once signed in.
void main() {
  setUpAll(loadFonts);
  final article = FakeApi.data('en')['article'] as Map<String, dynamic>;
  final path = article['path'] as String;
  final id = article['id'] as String;
  const user = {
    'id': 'r1',
    'display_name': '',
    'username': 'msomaji',
    'initial': 'M',
    'phone': '+255712345678',
    'email': '',
    'onboarding': true,
    'hide_from_readers': false,
  };

  FakeApi reader({bool phone = true}) => FakeApi()
    ..replies.addAll({
      '/api/v1/auth/methods': {
        'phone': phone,
        'google': false,
        'apple': false,
        'resend_seconds': 60,
      },
      '/api/v1/engagement/state': {
        id: {'views': 40, 'readers': 30, 'likes': 2, 'comments': 0, 'liked': false},
      },
      '/api/v1/engagement/posts/$id/opened': {
        'views': 41,
        'readers': 31,
        'likes': 2,
        'comments': 0,
      },
      '/api/v1/auth/code': {'challenge': 'c1', 'phone': '+255712345678', 'resend_in': 60},
      '/api/v1/auth/code/verify': {'access': 'a1', 'refresh': 'r1', 'user': user},
      '/api/v1/me': {...user, 'display_name': 'Asha', 'onboarding': false},
      '/api/v1/engagement/posts/$id/like': {'likes': 3, 'comments': 0, 'liked': true},
    });

  Iterable<RequestOptions> sent(FakeApi api, String method, String end) =>
      api.asked.where((o) => o.method == method && o.uri.path.endsWith(end));

  testWidgets('a guest likes a story: phone, code, name, and the like is done after', (t) async {
    final api = reader();
    final p = await start(t, api: api, locale: 'en');
    await p.push(path);
    expect(find.descendant(of: find.byType(LikeButton), matching: find.text('2')), findsOneWidget);

    await t.tap(find.byType(LikeButton));
    await p.settle();
    expect(find.byType(SignInSheet), findsOneWidget);
    expect(find.text('Sign in to like this story'), findsOneWidget);
    expect(sent(api, 'PUT', '/like'), isEmpty, reason: 'nothing is done before signing in');

    await t.enterText(find.byType(TextField), '712 345 678');
    await t.tap(find.text('Send code'));
    await p.settle();
    expect(sent(api, 'POST', '/auth/code').single.data, {'phone': '+255712345678', 'locale': 'en'});

    // Six digits verify on their own, as an SMS autofill would leave them.
    await t.enterText(find.byType(TextField), '123456');
    await p.settle();
    expect(sent(api, 'POST', '/auth/code/verify').single.data, {
      'challenge': 'c1',
      'code': '123456',
      'device': 'app',
    });

    // A new reader says a name and accepts the terms with one tick, never without it.
    await t.enterText(find.byType(TextField), 'Asha');
    await t.tap(find.text('Continue'));
    await p.settle();
    expect(sent(api, 'PATCH', '/api/v1/me'), isEmpty);
    expect(find.text('I accept the community guidelines and the privacy policy'), findsWidgets);
    await t.tap(find.byType(Checkbox));
    await t.tap(find.text('Continue'));
    await p.settle();
    expect(sent(api, 'PATCH', '/api/v1/me').single.data, {
      'display_name': 'Asha',
      'accept_terms': true,
    });

    expect(find.byType(SignInSheet), findsNothing);
    expect(p.container.read(readerProvider)?.name, 'Asha');
    expect(sent(api, 'PUT', '/posts/$id/like'), hasLength(1), reason: 'the intent is resumed');
    expect(
      sent(api, 'PUT', '/like').single.headers['Authorization'],
      'Bearer a1',
      reason: 'the access token goes on every request',
    );
    expect(find.descendant(of: find.byType(LikeButton), matching: find.text('3')), findsOneWidget);
  });

  testWidgets('a wrong code says how many tries are left, and the sheet stays', (t) async {
    final api = reader()
      ..replies['/api/v1/auth/code/verify'] = (400, {'code': 'code_wrong', 'attempts_left': 3});
    final p = await start(t, api: api, locale: 'en');
    await p.push(path);
    await t.tap(find.byType(LikeButton));
    await p.settle();
    await t.enterText(find.byType(TextField), '712345678');
    await t.tap(find.text('Send code'));
    await p.settle();
    await t.enterText(find.byType(TextField), '000000');
    await p.settle();
    expect(find.text('The code is not right. 3 tries left.'), findsOneWidget);
    expect(find.byType(SignInSheet), findsOneWidget);
    expect(p.container.read(readerProvider), isNull);
    expect(sent(api, 'PUT', '/like'), isEmpty);
  });

  testWidgets('with SMS switched off the sheet says so and offers no field', (t) async {
    final p = await start(t, api: reader(phone: false), locale: 'en');
    await p.push(path);
    await t.tap(find.byType(LikeButton));
    await p.settle();
    expect(find.text('SMS cannot be sent right now. Try later.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('a like the server refuses goes back', (t) async {
    final api = reader()..replies['/api/v1/engagement/posts/$id/like'] = 503;
    final p = await start(t, api: api, locale: 'en');
    // Tokens the keychain kept from an earlier start.
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => call.method == 'read'
          ? {'reader_access': 'a1', 'reader_refresh': 'r1'}[(call.arguments as Map)['key']]
          : null,
    );
    p.container.invalidate(sessionProvider);
    await p.settle();
    await p.push(path);
    expect(p.container.read(readerProvider), isNotNull);
    await t.tap(find.byType(LikeButton));
    await p.settle();
    expect(find.byType(SignInSheet), findsNothing, reason: 'already signed in');
    expect(sent(api, 'PUT', '/like'), hasLength(1));
    expect(find.descendant(of: find.byType(LikeButton), matching: find.text('2')), findsOneWidget);
  });

  // Counts on cards, before a story is opened (Settings → Engagement, on by default).
  Map<String, dynamic> everyone(RequestOptions o, {bool likesOn = true}) => {
    for (final id in o.uri.queryParameters['posts']!.split(','))
      id: {
        'views': 1200,
        'readers': 900,
        'likes': 12,
        'comments': 4,
        'bookmarks': 0,
        'liked': false,
        'bookmarked': false,
        'likes_on': likesOn,
        'comments_on': true,
      },
  };

  testWidgets('cards show views, likes and comments before a story is opened', (t) async {
    final api = FakeApi()..replies['/api/v1/engagement/state'] = everyone;
    final p = await start(t, api: api, locale: 'en');
    await p.settle();
    expect(find.byType(CardCounts), findsWidgets);
    expect(find.text('12'), findsWidgets, reason: 'likes');
    expect(find.text('4'), findsWidgets, reason: 'comments');
    expect(find.text('1.2K'), findsWidgets, reason: 'views on the line');
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == '1200 views, 12 likes, 4 comments',
      ),
      findsWidgets,
      reason: 'read aloud whole',
    );
    expect(sent(api, 'GET', '/engagement/state').length, lessThan(4), reason: 'asked together');
  });

  testWidgets('a story that does not allow likes shows no likes on its card', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/engagement/state'] = (RequestOptions o) => everyone(o, likesOn: false);
    final p = await start(t, api: api, locale: 'en');
    await p.settle();
    expect(find.text('4'), findsWidgets);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('switched off in the admin, cards show no counts and ask for none', (t) async {
    final api = FakeApi()
      ..replies['/api/v1/engagement/state'] = everyone
      ..replies['/api/v1/app-config'] = FakeApi.config({
        'flags': {'shorts': true, 'youtube': true, 'offline_saving': true, 'card_counts': false},
      });
    final p = await start(t, api: api, locale: 'en');
    await p.settle();
    expect(find.text('12'), findsNothing);
    expect(find.text('1.2K'), findsNothing);
    expect(sent(api, 'GET', '/engagement/state'), isEmpty);
  });
}
