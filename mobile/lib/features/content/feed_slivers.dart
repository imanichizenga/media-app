import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../app/window.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/theme.dart';
import 'feeds.dart';

/// Stories one under another on a phone, in columns where there is room.
class StorySliver extends StatelessWidget {
  const StorySliver({
    super.key,
    required this.stories,
    required this.open,
    required this.place,
    this.feature = false,
  });

  final List<Story?> stories;
  final OpenStory open;
  final String place;

  /// Give every sixth story room.
  final bool feature;

  @override
  Widget build(BuildContext context) {
    final columns = switch (windowOf(context)) {
      WindowClass.compact => 1,
      WindowClass.medium => 2,
      WindowClass.expanded => 3,
    };
    if (columns > 1) {
      final rows = (stories.length / columns).ceil();
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
        sliver: SliverList.builder(
          itemCount: rows,
          itemBuilder: (context, r) => Padding(
            padding: const EdgeInsets.only(top: NewsSpace.s5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = r * columns; i < (r + 1) * columns; i++) ...[
                  if (i > r * columns) const SizedBox(width: NewsSpace.s6),
                  Expanded(
                    child: i < stories.length
                        ? (stories[i]?.isVideo ?? false)
                              ? VideoCard(stories[i], open: open, place: place)
                              : StandardCard(stories[i], open: open, place: place, large: false)
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
      sliver: SliverList.separated(
        itemCount: stories.length,
        separatorBuilder: (context, i) => Divider(color: context.colors.border),
        itemBuilder: (context, i) => RepaintBoundary(
          key: ValueKey(stories[i]?.id ?? 'bone$i'),
          child: FeedCard(stories[i], open: open, place: place, feature: feature && i % 6 == 3),
        ),
      ),
    );
  }
}

/// A whole feed: its bones, its stories, its end, its failures.
List<Widget> feedSlivers(
  BuildContext context,
  WidgetRef ref, {
  required FeedKey feed,
  required OpenStory open,
  required String place,
  Set<String> hide = const {},
  int skip = 0,
}) {
  final state = ref.watch(feedProvider(feed));
  final s = Strings.of(context);
  if (state case AsyncError(:final error) when state.value == null) {
    return [
      SliverToBoxAdapter(
        child: Designed.failure(
          context,
          error,
          retry: () => ref.invalidate(feedProvider(feed)),
          home: () => const HomeRoute().go(context),
          saved: error is OfflineFailure ? () => const SavedRoute().go(context) : null,
        ),
      ),
    ];
  }
  final now = state.value;
  if (now == null) {
    return [StorySliver(stories: List.filled(8, null), open: open, place: place)];
  }
  final stories = now.stories.where((x) => !hide.contains(x.id)).skip(skip).toList();
  if (stories.isEmpty && skip == 0) {
    return [
      SliverToBoxAdapter(
        child: Designed(
          drawing: Drawing.empty,
          title: s.feedEmptyTitle,
          body: s.feedEmptyBody,
          action: s.goHome,
          onAction: () => const HomeRoute().go(context),
        ),
      ),
    ];
  }
  return [
    StorySliver(stories: stories, open: open, place: place, feature: true),
    if (now.next != null && !now.moreFailed)
      StorySliver(stories: List.filled(2, null), open: open, place: '$place-more'),
    if (now.moreFailed)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(NewsSpace.s6),
          child: Center(
            child: NewsButton(
              s.retry,
              kind: ButtonKind.secondary,
              onTap: () => ref.read(feedProvider(feed).notifier).loadMore(),
            ),
          ),
        ),
      ),
  ];
}
