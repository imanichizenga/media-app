import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'session.dart';

/// A story's counts, and what this reader did with it (ADR-0050).
class PostState {
  const PostState({
    this.views = 0,
    this.readers = 0,
    this.likes = 0,
    this.comments = 0,
    this.liked = false,
    this.bookmarked = false,
    this.likesOn = true,
    this.commentsOn = true,
  });

  factory PostState.fromJson(Map<String, dynamic> j) => PostState(
    views: (j['views'] as num?)?.toInt() ?? 0,
    readers: (j['readers'] as num?)?.toInt() ?? 0,
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    comments: (j['comments'] as num?)?.toInt() ?? 0,
    liked: j['liked'] == true,
    bookmarked: j['bookmarked'] == true,
    likesOn: j['likes_on'] != false,
    commentsOn: j['comments_on'] != false,
  );

  final int views;
  final int readers;
  final int likes;
  final int comments;
  final bool liked;
  final bool bookmarked;

  /// What the story allows now: a count it does not allow is never shown on its card.
  final bool likesOn;
  final bool commentsOn;

  PostState copyWith({int? likes, int? comments, bool? liked}) => PostState(
    views: views,
    readers: readers,
    likes: likes ?? this.likes,
    comments: comments ?? this.comments,
    liked: liked ?? this.liked,
    bookmarked: bookmarked,
    likesOn: likesOn,
    commentsOn: commentsOn,
  );
}

/// Counts for many stories at once: cards ask one by one, and are answered together a moment later.
class _Batcher {
  _Batcher(this.dio);

  final Dio dio;
  final _waiting = <String, Completer<PostState>>{};
  Timer? _timer;

  Future<PostState> ask(String id) {
    final c = _waiting.putIfAbsent(id, Completer<PostState>.new);
    _timer ??= Timer(const Duration(milliseconds: 60), _flush);
    return c.future;
  }

  Future<void> _flush() async {
    _timer = null;
    final batch = Map.of(_waiting);
    _waiting.clear();
    final ids = batch.keys.toList();
    for (var i = 0; i < ids.length; i += 50) {
      final part = ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50);
      try {
        final r = await dio.get<Map<String, dynamic>>(
          '/api/v1/engagement/state',
          queryParameters: {'posts': part.join(',')},
        );
        for (final id in part) {
          final found = r.data?[id];
          batch[id]!.complete(
            found is Map<String, dynamic> ? PostState.fromJson(found) : const PostState(),
          );
        }
      } on DioException catch (e) {
        for (final id in part) {
          batch[id]!.completeError(e);
        }
      }
    }
  }
}

final _batcherProvider = Provider<_Batcher>((ref) => _Batcher(ref.watch(dioProvider)));

/// A story's state. Signed in or out changes what "liked" means: it is asked again then.
class PostStateNotifier extends AsyncNotifier<PostState> {
  PostStateNotifier(this.id);

  final String id;

  @override
  Future<PostState> build() {
    ref.watch(readerProvider.select((r) => r?.id));
    return ref.read(_batcherProvider).ask(id);
  }

  /// The story was opened: counted (one device once in 30 minutes), and the fresh counts come back.
  Future<void> opened() async {
    try {
      final r = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/api/v1/engagement/posts/$id/opened',
            data: {'device': ref.read(deviceIdProvider) ?? ''},
          );
      state = AsyncData(PostState.fromJson(r.data!));
    } on DioException {
      // Counting is not worth an error.
    }
  }

  /// Optimistic: the heart changes at once and goes back if the server says no.
  Future<void> toggleLike() async {
    final before = state.value ?? const PostState();
    final on = !before.liked;
    state = AsyncData(
      before.copyWith(liked: on, likes: (before.likes + (on ? 1 : -1)).clamp(0, 1 << 31)),
    );
    try {
      final path = '/api/v1/engagement/posts/$id/like';
      final dio = ref.read(dioProvider);
      final r = on
          ? await dio.put<Map<String, dynamic>>(path)
          : await dio.delete<Map<String, dynamic>>(path);
      state = AsyncData(
        PostState.fromJson({...?r.data, 'views': before.views, 'readers': before.readers}),
      );
    } on DioException {
      state = AsyncData(before);
    }
  }

  void commented() {
    final now = state.value;
    if (now != null) state = AsyncData(now.copyWith(comments: now.comments + 1));
  }
}

final postStateProvider = AsyncNotifierProvider.family<PostStateNotifier, PostState, String>(
  PostStateNotifier.new,
);
