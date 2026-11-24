import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'failures.dart';
import 'interceptors.dart';

/// A value, how old it is, and what went wrong while refreshing it, if anything did.
@immutable
class Loaded<T> {
  const Loaded(this.value, {required this.at, this.failure});

  final T value;
  final DateTime at;
  final Failure? failure;

  Loaded<T> failed(Failure f) => Loaded(value, at: at, failure: f);
}

typedef Call<T> = Future<Response<T>> Function(Map<String, dynamic> extra);

/// From the phone only. Null when there is nothing, or what there is belongs to an older shape of the API.
Future<Loaded<T>?> fromCache<T>(Call<T> call) async {
  try {
    final r = await call({...cacheOnly});
    return Loaded(r.data as T, at: r.extra['fetchedAt'] as DateTime? ?? DateTime.now());
  } on Object {
    return null;
  }
}

Future<Loaded<T>> fromNetwork<T>(Call<T> call) async {
  try {
    final r = await call({});
    return Loaded(r.data as T, at: DateTime.now());
  } on Object catch (e) {
    throw Failure.from(e);
  }
}
