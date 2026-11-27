import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/account/counts.dart';
import '../../core/account/session.dart';
import '../../core/format/format.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import 'sign_in.dart';

/// Under the byline: views, and readers, who open the list of who read it.
class StoryStats extends ConsumerWidget {
  const StoryStats(this.postId, {super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final state = ref.watch(postStateProvider(postId)).value;
    final style = context.type.caption.copyWith(color: c.textSecondary);
    String n(int? v) => v == null ? '–' : compact(v);
    return Row(
      children: [
        Semantics(
          label: state == null ? null : s.viewsCount(state.views),
          excludeSemantics: true,
          child: Row(
            children: [
              NewsIcon(NewsIcons.eye, size: 15, color: c.textSecondary),
              const SizedBox(width: 4),
              Text(n(state?.views), style: style),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Pressable(
          label: state == null ? s.readersTitle : s.readersCount(state.readers),
          onTap: () => unawaited(showReaders(context, postId)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                NewsIcon(NewsIcons.users, size: 15, color: c.textSecondary),
                const SizedBox(width: 4),
                Text(n(state?.readers), style: style),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The heart, with its count: a guest is asked to sign in first, and the like is done after.
class LikeButton extends ConsumerWidget {
  const LikeButton(this.postId, {super.key});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final state = ref.watch(postStateProvider(postId)).value ?? const PostState();
    return Pressable(
      label: '${s.likeStory}, ${s.likesCount(state.likes)}',
      scale: 0.9,
      onTap: () async {
        if (!await requireReader(context, ref, intent: s.signInToLike)) return;
        unawaited(HapticFeedback.lightImpact());
        await ref.read(postStateProvider(postId).notifier).toggleLike();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: state.liked ? 1.0 : 0.94,
              duration: context.still ? Duration.zero : const Duration(milliseconds: 220),
              curve: Curves.elasticOut,
              child: NewsIcon(
                NewsIcons.heart,
                size: 23,
                color: state.liked ? c.liked : c.textSecondary,
                filled: state.liked,
              ),
            ),
            if (state.likes > 0) ...[
              const SizedBox(width: 4),
              Text(
                compact(state.likes),
                style: context.type.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommentsButton extends ConsumerWidget {
  const CommentsButton(this.postId, {super.key, required this.open});

  final String postId;
  final VoidCallback open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final count = ref.watch(postStateProvider(postId).select((s) => s.value?.comments ?? 0));
    return Pressable(
      label: Strings.of(context).comments,
      scale: 0.9,
      onTap: open,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NewsIcon(NewsIcons.messageCircle, size: 22, color: c.textSecondary),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(compact(count), style: context.type.caption.copyWith(color: c.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _avatar(BuildContext context, String initial, {double size = 36}) {
  final c = context.colors;
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
    child: Text(
      initial,
      style: context.type.label.copyWith(color: c.brandText, fontWeight: FontWeight.w700),
    ),
  );
}

/// Who read the story: signed-in readers who did not hide, newest first, and how many guests.
Future<void> showReaders(BuildContext context, String postId) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _ReadersSheet(postId),
);

class _ReadersSheet extends ConsumerWidget {
  const _ReadersSheet(this.postId);

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: FutureBuilder(
        future: ref
            .read(dioProvider)
            .get<Map<String, dynamic>>('/api/v1/engagement/posts/$postId/readers'),
        builder: (context, snap) {
          final data = snap.data?.data;
          final list = (data?['results'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
          final guests = (data?['guests'] as num?)?.toInt() ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    NewsIcon(NewsIcons.users, size: 20, color: c.textSecondary),
                    const SizedBox(width: 10),
                    Semantics(
                      header: true,
                      child: Text(
                        s.readersTitle,
                        style: type.headlineS.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              if (data != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    list.isEmpty ? s.readersNone : (guests > 0 ? s.readersGuests(guests) : ''),
                    style: type.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              Expanded(
                child: snap.connectionState != ConnectionState.done
                    ? const _PeopleSkeleton()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              _avatar(context, list[i]['initial'] as String? ?? '?'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      list[i]['name'] as String? ?? '',
                                      style: type.label.copyWith(color: c.textPrimary),
                                    ),
                                    Text(
                                      '@${list[i]['username']}',
                                      style: type.caption.copyWith(color: c.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A comment as `/api/v1/engagement/posts/{id}/comments` gives it.
class Remark {
  Remark.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      body = j['body'] as String,
      at = DateTime.parse(j['created_at'] as String),
      name = ((j['author'] as Map)['name'] as String?) ?? '',
      initial = ((j['author'] as Map)['initial'] as String?) ?? '?',
      writer = (j['author'] as Map)['is_writer'] == true,
      likes = (j['like_count'] as num).toInt(),
      replies = (j['reply_count'] as num).toInt(),
      liked = j['liked'] == true,
      mine = j['mine'] == true,
      held = j['held'] == true,
      parent = j['parent'] as String?;

  final String id;
  final String body;
  final DateTime at;
  final String name;
  final String initial;
  final bool writer;
  int likes;
  final int replies;
  bool liked;
  final bool mine;
  final bool held;
  final String? parent;
}

/// Comments, Instagram's way (SPEC): a sheet, newest first, replies one level under, a like for each, the writer
/// marked, the composer pinned at the foot above the keyboard.
Future<void> showComments(BuildContext context, String postId) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CommentsSheet(postId),
);

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet(this.postId, {super.key});

  final String postId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _items = <Remark>[];
  final _replies = <String, List<Remark>>{};
  String? _cursor;
  var _loading = true;
  var _closed = false;
  var _sending = false;
  Remark? _replyTo;

  Dio get _dio => ref.read(dioProvider);
  String get _base => '/api/v1/engagement/posts/${widget.postId}/comments';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        _base,
        queryParameters: {if (more && _cursor != null) 'cursor': _cursor},
      );
      final d = r.data!;
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll((d['results'] as List).cast<Map<String, dynamic>>().map(Remark.fromJson));
        _cursor = d['next_cursor'] as String?;
        _closed = (d['policy'] as Map?)?['comments'] == 'closed';
        _loading = false;
      });
    } on DioException {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReplies(Remark top) async {
    final r = await _dio.get<Map<String, dynamic>>(_base, queryParameters: {'parent': top.id});
    if (!mounted) return;
    setState(
      () => _replies[top.id] = (r.data!['results'] as List)
          .cast<Map<String, dynamic>>()
          .map(Remark.fromJson)
          .toList(),
    );
  }

  Future<void> _send() async {
    final s = Strings.of(context);
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    if (!await requireReader(context, ref, intent: s.signInToComment)) return;
    setState(() => _sending = true);
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        _base,
        data: {'body': body, 'parent': ?_replyTo?.id},
      );
      final made = Remark.fromJson(r.data!);
      setState(() {
        if (made.parent case final parent?) {
          (_replies[parent] ??= []).add(made);
        } else {
          _items.insert(0, made);
        }
        _text.clear();
        _replyTo = null;
      });
      if (!made.held) ref.read(postStateProvider(widget.postId).notifier).commented();
      unawaited(HapticFeedback.lightImpact());
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e.response?.statusCode == 429 ? s.commentSlow : s.commentFailed)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _like(Remark m) async {
    if (!await requireReader(context, ref, intent: Strings.of(context).signInToLike)) return;
    final on = !m.liked;
    setState(() {
      m.liked = on;
      m.likes += on ? 1 : -1;
    });
    unawaited(HapticFeedback.lightImpact());
    try {
      final path = '/api/v1/engagement/comments/${m.id}/like';
      if (on) {
        await _dio.put<void>(path);
      } else {
        await _dio.delete<void>(path);
      }
    } on DioException {
      if (mounted) {
        setState(() {
          m.liked = !on;
          m.likes += on ? -1 : 1;
        });
      }
    }
  }

  Future<void> _delete(Remark m) async {
    try {
      await _dio.delete<void>('/api/v1/engagement/comments/${m.id}');
      setState(() {
        _items.remove(m);
        for (final list in _replies.values) {
          list.remove(m);
        }
      });
    } on DioException {
      // Left as it was.
    }
  }

  String _ago(DateTime at, Strings s) => ago(at, s, ref.read(clockNowProvider)());

  Widget _row(Remark m, {required bool reply}) {
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    final replies = _replies[m.id];
    return Padding(
      padding: EdgeInsets.only(left: reply ? 46 : 0, top: 10, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(context, m.initial, size: reply ? 28 : 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      m.name,
                      style: type.label.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    if (m.writer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: c.brand,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          s.commentWriter.toUpperCase(),
                          style: type.caption.copyWith(
                            color: c.onBrand,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(_ago(m.at, s), style: type.caption.copyWith(color: c.textSecondary)),
                    if (m.held)
                      Text('· ${s.commentHeld}', style: type.caption.copyWith(color: c.warning)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(m.body, style: type.bodyM.copyWith(color: c.textPrimary)),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(
                          () => _replyTo = reply
                              ? _items.firstWhere((t) => t.id == m.parent, orElse: () => m)
                              : m,
                        );
                        _focus.requestFocus();
                      },
                      child: Text(
                        s.commentReply,
                        style: type.caption.copyWith(color: c.textSecondary),
                      ),
                    ),
                    if (m.mine)
                      TextButton(
                        onPressed: () => unawaited(_delete(m)),
                        child: Text(
                          s.commentDelete,
                          style: type.caption.copyWith(color: c.textSecondary),
                        ),
                      ),
                  ],
                ),
                if (!reply && m.replies > 0 && replies == null)
                  TextButton(
                    onPressed: () => unawaited(_loadReplies(m)),
                    child: Text(
                      '—  ${s.commentReplies(m.replies)}',
                      style: type.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                for (final r in replies ?? const <Remark>[]) _row(r, reply: true),
              ],
            ),
          ),
          Pressable(
            label: s.likeStory,
            onTap: () => unawaited(_like(m)),
            child: SizedBox(
              width: 40,
              height: 48,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  NewsIcon(
                    NewsIcons.heart,
                    size: 15,
                    color: m.liked ? c.liked : c.textTertiary,
                    filled: m.liked,
                  ),
                  if (m.likes > 0)
                    Text(
                      compact(m.likes),
                      style: type.caption.copyWith(color: c.textTertiary, fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final c = context.colors;
    final type = context.type;
    final me = ref.watch(readerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          children: [
            Semantics(
              header: true,
              child: Text(s.comments, style: type.headlineS.copyWith(color: c.textPrimary)),
            ),
            Divider(color: c.border),
            Expanded(
              child: _loading
                  ? const _PeopleSkeleton(lines: 2)
                  : _items.isEmpty
                  ? Center(
                      child: Text(
                        _closed ? s.commentsClosed : s.commentsNone,
                        style: type.bodyM.copyWith(color: c.textSecondary),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        for (final m in _items) _row(m, reply: false),
                        if (_cursor != null)
                          TextButton(
                            onPressed: () => unawaited(_load(more: true)),
                            child: Text(s.commentsMore),
                          ),
                      ],
                    ),
            ),
            if (!_closed)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  border: Border(top: BorderSide(color: c.border, width: 0.5)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_replyTo case final to?)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.commentReplyTo(to.name),
                                  style: type.caption.copyWith(color: c.textSecondary),
                                ),
                              ),
                              IconButton(
                                tooltip: s.close,
                                onPressed: () => setState(() => _replyTo = null),
                                icon: NewsIcon(NewsIcons.x, size: 16, color: c.textSecondary),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            _avatar(context, me?.initial ?? '?', size: 34),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _text,
                                focusNode: _focus,
                                minLines: 1,
                                maxLines: 5,
                                maxLength: 2000,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: s.commentPlaceholder,
                                  counterText: '',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            ),
                            IconButton.filled(
                              tooltip: s.commentSend,
                              onPressed: _sending ? null : () => unawaited(_send()),
                              style: IconButton.styleFrom(
                                backgroundColor: c.brand,
                                foregroundColor: c.onBrand,
                              ),
                              icon: NewsIcon(NewsIcons.sendHorizontal, size: 18, color: c.onBrand),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rows of people (readers, or comments with their first lines) while the list comes.
class _PeopleSkeleton extends StatelessWidget {
  const _PeopleSkeleton({this.lines = 1});

  final int lines;

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Bone(width: 36, height: 36, radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Bone(width: 120, height: 14),
                      for (var l = 0; l < lines; l++) ...[
                        const SizedBox(height: 6),
                        FractionallySizedBox(
                          widthFactor: l == lines - 1 ? 0.6 : 1,
                          child: const Bone(width: null, height: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
