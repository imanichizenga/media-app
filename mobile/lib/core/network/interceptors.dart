import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:news_api_client/news_api_client.dart' show PostTypeEnum;

import '../storage/database.dart';
import 'failures.dart';

/// Pass as `extra` to any generated call: answer from the phone, or not at all.
const cacheOnly = <String, dynamic>{'cacheOnly': true};
const _isolateAbove = 60 * 1024;

Future<Object?> decodeJson(String body) =>
    body.length > _isolateAbove ? compute(jsonDecode, body) : Future.value(jsonDecode(body));

/// Keeps every answer, asks the server only whether it changed, and can answer without the network.
class CacheInterceptor extends Interceptor {
  CacheInterceptor(this.db);

  final AppDatabase db;

  static String keyOf(RequestOptions o) => '${o.uri.path}?${o.uri.query}';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.method != 'GET') return handler.next(options);
    final entry = await db.cached(keyOf(options));
    if (options.extra['cacheOnly'] == true) {
      if (entry == null) {
        return handler.reject(DioException(requestOptions: options, error: const CacheMiss()));
      }
      return handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: await decodeJson(entry.body),
          extra: {'fetchedAt': entry.fetchedAt},
        ),
      );
    }
    if (entry != null && entry.etag.isNotEmpty) {
      options.headers['If-None-Match'] = entry.etag;
      options.extra['entry'] = entry;
    }
    final accepts = options.validateStatus;
    options.validateStatus = (s) => s == 304 || accepts(s);
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final options = response.requestOptions;
    if (options.method == 'GET') {
      final key = keyOf(options);
      if (response.statusCode == 304) {
        final entry = options.extra['entry'] as CacheEntry;
        unawaited(db.touch(key));
        response
          ..statusCode = 200
          ..data = await decodeJson(entry.body)
          ..extra['unchanged'] = true;
      } else if (response.statusCode == 200 &&
          response.data is Object &&
          // A reader's own answers say no-store (ADR-0050): never kept on the phone.
          !(response.headers.value('cache-control') ?? '').contains('no-store') &&
          options.headers['Authorization'] == null) {
        dropUnknown(response.data as Object?);
        unawaited(db.store(key, response.headers.value('etag') ?? '', jsonEncode(response.data)));
      }
    }
    handler.next(response);
  }
}

final _types = {for (final t in PostTypeEnum.values) t.value};

/// A kind of story this version has never heard of must not take the whole list down with it.
void dropUnknown(Object? data) {
  if (data is List) {
    data.removeWhere((e) => e is Map && e.containsKey('headline') && !_types.contains(e['type']));
    data.forEach(dropUnknown);
  } else if (data is Map) {
    data.values.forEach(dropUnknown);
  }
}

/// Reads only, at most twice more, later each time and never in step with other phones.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this.dio, {this.retries = 2, this.base = const Duration(milliseconds: 400)});

  final Dio dio;
  final int retries;
  final Duration base;
  final _random = Random();

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final tried = options.extra['tried'] as int? ?? 0;
    final status = err.response?.statusCode;
    final worth =
        status == 502 ||
        status == 503 ||
        status == 504 ||
        status == 429 ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
    if (options.method != 'GET' || !worth || tried >= retries) return handler.next(err);
    final wait = base * pow(2, tried).toInt();
    await Future<void>.delayed(wait * (0.5 + _random.nextDouble()));
    options.extra['tried'] = tried + 1;
    try {
      handler.resolve(await dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}

/// Who is asking: language, version, platform, and a random id that belongs to this installation only.
class IdentityInterceptor extends Interceptor {
  IdentityInterceptor({required this.locale, required this.fixed, required this.deviceId});

  final String Function() locale;
  final Map<String, String> fixed;
  final String? Function() deviceId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll(fixed);
    options.headers['Accept-Language'] = locale();
    if (deviceId() case final id?) options.headers['X-Device-Id'] = id;
    handler.next(options);
  }
}

/// A random version 4 UUID.
class Uuidish {
  const Uuidish();

  String v4() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0F) | 0x40;
    b[8] = (b[8] & 0x3F) | 0x80;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }
}
