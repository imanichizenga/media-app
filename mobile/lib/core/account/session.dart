import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../providers.dart';

/// The signed-in reader (ADR-0050), as `/api/v1/me` says.
class Reader {
  const Reader({
    required this.id,
    required this.displayName,
    required this.username,
    required this.initial,
    required this.phone,
    required this.email,
    required this.onboarding,
    required this.hideFromReaders,
  });

  factory Reader.fromJson(Map<String, dynamic> j) => Reader(
    id: j['id'] as String,
    displayName: (j['display_name'] as String?) ?? '',
    username: (j['username'] as String?) ?? '',
    initial: (j['initial'] as String?) ?? '?',
    phone: (j['phone'] as String?) ?? '',
    email: (j['email'] as String?) ?? '',
    onboarding: (j['onboarding'] as bool?) ?? false,
    hideFromReaders: (j['hide_from_readers'] as bool?) ?? false,
  );

  final String id;
  final String displayName;
  final String username;
  final String initial;
  final String phone;
  final String email;
  final bool onboarding;
  final bool hideFromReaders;

  String get name => displayName.isNotEmpty ? displayName : username;
}

/// Which ways of signing in are open: switched on in the admin and their vendor active.
class SignInMethods {
  const SignInMethods({
    this.phone = false,
    this.google = false,
    this.apple = false,
    this.localSms = false,
    this.resendSeconds = 60,
    this.googleClientId = '',
  });

  factory SignInMethods.fromJson(Map<String, dynamic> j) => SignInMethods(
    phone: j['phone'] == true,
    google: j['google'] == true,
    apple: j['apple'] == true,
    localSms: j['local_sms'] == true,
    resendSeconds: (j['resend_seconds'] as num?)?.toInt() ?? 60,
    googleClientId: (j['google_client_id'] as String?) ?? '',
  );

  final bool phone;
  final bool google;
  final bool apple;
  final bool localSms;
  final int resendSeconds;
  final String googleClientId;
}

/// A refusal from the API: `code` is what the app branches on, never the text.
class Refused implements Exception {
  const Refused(this.code, {this.attemptsLeft, this.retryAfter});

  final String code;
  final int? attemptsLeft;
  final int? retryAfter;

  static Refused of(DioException e) {
    final data = e.response?.data;
    final map = data is Map ? data : const <String, dynamic>{};
    return Refused(
      (map['code'] as String?) ?? (e.response == null ? 'offline' : 'error'),
      attemptsLeft: (map['attempts_left'] as num?)?.toInt(),
      retryAfter: int.tryParse(e.response?.headers.value('retry-after') ?? ''),
    );
  }
}

class Sent {
  const Sent({
    required this.challenge,
    required this.phone,
    required this.resendIn,
    this.localCode,
  });

  final String challenge;
  final String phone;
  final int resendIn;

  /// Development only (LOCAL_SMS): the code comes back on screen, never by SMS.
  final String? localCode;
}

/// Tokens in the keychain; a refresh token is used once and its successor kept (rotation, ADR-0050).
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  String? access;
  String? refresh;

  Future<void> load() async {
    try {
      access = await _storage.read(key: 'reader_access');
      refresh = await _storage.read(key: 'reader_refresh');
    } on Exception {
      access = refresh = null;
    }
  }

  Future<void> keep(Map<String, dynamic> pair) async {
    access = pair['access'] as String?;
    refresh = pair['refresh'] as String?;
    try {
      await _storage.write(key: 'reader_access', value: access);
      await _storage.write(key: 'reader_refresh', value: refresh);
    } on Exception {
      // A locked keychain: signed in for this session only.
    }
  }

  Future<void> clear() async {
    access = refresh = null;
    try {
      await _storage.delete(key: 'reader_access');
      await _storage.delete(key: 'reader_refresh');
    } on Exception {
      // Nothing to clear.
    }
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

/// Puts the reader's access token on every request, and when it has expired, renews it once with the refresh token
/// (in a plain client, so the renewal never loops) and tries again. A refused renewal signs the reader out.
class ReaderAuthInterceptor extends QueuedInterceptor {
  ReaderAuthInterceptor(this.store, this.baseUrl, this.onSignedOut);

  final TokenStore store;
  final String baseUrl;
  final void Function() onSignedOut;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (store.access case final token?) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final refresh = store.refresh;
    final retried = err.requestOptions.extra['renewed'] == true;
    if (err.response?.statusCode != 401 || refresh == null || retried) return handler.next(err);
    try {
      final plain = Dio(BaseOptions(baseUrl: baseUrl, connectTimeout: const Duration(seconds: 8)));
      final answer = await plain.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        data: {'refresh': refresh},
      );
      await store.keep(answer.data!);
      final again = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${store.access}'
        ..extra['renewed'] = true;
      handler.resolve(await plain.fetch<dynamic>(again));
    } on DioException {
      await store.clear();
      onSignedOut();
      handler.next(err);
    }
  }
}

/// Who is signed in, and every way to sign in, change the account and leave.
class Session extends AsyncNotifier<Reader?> {
  Dio get _dio => ref.read(dioProvider);
  TokenStore get _store => ref.read(tokenStoreProvider);

  @override
  Future<Reader?> build() async {
    await _store.load();
    final dio = ref.read(dioProvider);
    if (!dio.interceptors.any((i) => i is ReaderAuthInterceptor)) {
      dio.interceptors.insert(
        0,
        ReaderAuthInterceptor(_store, dio.options.baseUrl, () => state = const AsyncData(null)),
      );
    }
    if (_store.refresh == null) return null;
    try {
      final me = await dio.get<Map<String, dynamic>>('/api/v1/me');
      return Reader.fromJson(me.data!);
    } on DioException {
      return null; // offline or signed out elsewhere: a guest until the next start
    }
  }

  Future<SignInMethods> methods() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>('/api/v1/auth/methods');
      return SignInMethods.fromJson(r.data!);
    } on DioException {
      return const SignInMethods();
    }
  }

  Future<Sent> requestCode(String phone, String locale) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/code',
        data: {'phone': phone, 'locale': locale},
      );
      final d = r.data!;
      return Sent(
        challenge: d['challenge'] as String,
        phone: d['phone'] as String,
        resendIn: (d['resend_in'] as num).toInt(),
        localCode: d['local_code'] as String?,
      );
    } on DioException catch (e) {
      throw Refused.of(e);
    }
  }

  /// Signed in: the new reader, who may still have to say a name ([Reader.onboarding]).
  Future<Reader> verify(String challenge, String code) =>
      _signIn('/api/v1/auth/code/verify', {'challenge': challenge, 'code': code, 'device': 'app'});

  /// The ID token the platform's own sign-in gave (Google, Apple); its audience is this app's client ID.
  Future<Reader> withProvider(String provider, String idToken, {String? nonce, String name = ''}) =>
      _signIn('/api/v1/auth/$provider', {
        'id_token': idToken,
        'nonce': ?nonce,
        'name': name,
        'device': 'app',
      });

  Future<Reader> _signIn(String path, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(path, data: body);
      await _store.keep(r.data!);
      final reader = Reader.fromJson(r.data!['user'] as Map<String, dynamic>);
      state = AsyncData(reader);
      return reader;
    } on DioException catch (e) {
      throw Refused.of(e);
    }
  }

  Future<Reader> saveProfile(Map<String, dynamic> changes) async {
    try {
      final r = await _dio.patch<Map<String, dynamic>>('/api/v1/me', data: changes);
      final reader = Reader.fromJson(r.data!);
      state = AsyncData(reader);
      return reader;
    } on DioException catch (e) {
      throw Refused.of(e);
    }
  }

  Future<void> signOut() async {
    final refresh = _store.refresh;
    await _store.clear();
    state = const AsyncData(null);
    if (refresh != null) unawaited(_forget(refresh));
  }

  Future<void> _forget(String refresh) async {
    try {
      await _dio.post<void>('/api/v1/auth/sign-out', data: {'refresh': refresh});
    } on DioException {
      // Offline: the token expires on its own, and is already gone from the phone.
    }
  }

  /// Signed out everywhere at once; erased after the grace period unless the reader signs in again.
  Future<void> delete() async {
    try {
      await _dio.delete<void>('/api/v1/me', data: {'confirm': 'delete'});
    } on DioException catch (e) {
      throw Refused.of(e);
    }
    await _store.clear();
    state = const AsyncData(null);
  }

  /// Everything kept about the reader, as JSON text (PDPA Tanzania 2022).
  Future<String> export() async {
    final r = await _dio.get<String>(
      '/api/v1/me/export',
      options: Options(responseType: ResponseType.plain),
    );
    return r.data ?? '';
  }
}

final sessionProvider = AsyncNotifierProvider<Session, Reader?>(Session.new);

/// The reader, or null for a guest (also while it is being asked).
final readerProvider = Provider<Reader?>((ref) => ref.watch(sessionProvider).value);
