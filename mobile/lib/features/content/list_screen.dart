import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../app/window.dart';
import '../../core/models.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/picture.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import 'feed_slivers.dart';
import 'feeds.dart';

/// A category, a tag, a developing story or an author: a title, what it is, its stories.
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.feed, required this.path});

  final FeedKey feed;
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedProvider(feed));
    final about = state.value?.about;
    final c = context.colors;
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: feed.kind.name);
    // An address that nothing answers to may have moved.
    if (state.hasError && state.value == null) {
      ref.listen(movedProvider(path), (_, next) {
        if (next.value case final target?) context.replace(target);
      });
    }
    final title =
        about?.category?.name ?? about?.tag?.name ?? about?.story?.title ?? about?.author?.name;
    final first = state.value?.stories.firstOrNull;
    final cover = feed.kind == FeedKind.category || feed.kind == FeedKind.story;
    final showCover =
        cover &&
        windowOf(context) == WindowClass.compact &&
        (state.value == null ? state.isLoading : first?.image != null);
    return Scaffold(
      body: Shimmer(
        child: RefreshIndicator(
          color: c.textPrimary,
          backgroundColor: c.surfaceRaised,
          edgeOffset: MediaQuery.paddingOf(context).top + 56,
          onRefresh: () => ref.read(feedProvider(feed).notifier).refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 1600) {
                unawaited(ref.read(feedProvider(feed).notifier).loadMore());
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TitleBar(
                    top: MediaQuery.paddingOf(context).top,
                    title: title ?? '',
                    colors: c,
                    back: Strings.of(context).back,
                  ),
                ),
                SliverToBoxAdapter(
                  child: switch (feed.kind) {
                    FeedKind.author => _AuthorHead(about?.author),
                    _ => _Head(
                      title: title,
                      text: about?.category?.description ?? about?.story?.summary ?? '',
                      children: about?.category?.children ?? const [],
                      loading: about == null,
                    ),
                  },
                ),
                if (showCover) ...[
                  SliverToBoxAdapter(
                    child: CoverCard(first, open: open, place: 'list'),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s2)),
                ],
                ...feedSlivers(
                  context,
                  ref,
                  feed: feed,
                  open: open,
                  place: 'list',
                  skip: showCover && first != null ? 1 : 0,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends SliverPersistentHeaderDelegate {
  const _TitleBar({
    required this.top,
    required this.title,
    required this.colors,
    required this.back,
  });

  final double top;
  final String title;
  final NewsColors colors;
  final String back;

  @override
  double get minExtent => top + 56;
  @override
  double get maxExtent => top + 56;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) => AnnotatedRegion(
    value: overlayFor(colors.mastheadBg),
    child: Container(
      padding: EdgeInsets.only(top: top, left: NewsSpace.s2, right: NewsSpace.s5),
      decoration: BoxDecoration(
        color: colors.mastheadBg,
        border: Border(
          bottom: BorderSide(color: overlaps ? colors.mastheadRule : colors.mastheadBg, width: 2),
        ),
      ),
      child: Row(
        children: [
          RoundButton(
            NewsIcons.arrowLeft,
            label: back,
            color: colors.mastheadFg,
            onTap: () => context.canPop() ? context.pop() : const HomeRoute().go(context),
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: overlaps ? 1 : 0,
              duration: NewsMotion.base,
              child: ExcludeSemantics(
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.2,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.headlineS.copyWith(color: colors.mastheadFg),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  bool shouldRebuild(_TitleBar old) => old.title != title || old.top != top || old.colors != colors;
}

class _Head extends StatelessWidget {
  const _Head({
    required this.title,
    required this.text,
    required this.children,
    required this.loading,
  });

  final String? title;
  final String text;
  final List<PublicCategory> children;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NewsSpace.s5,
            NewsSpace.s2,
            NewsSpace.s5,
            NewsSpace.s4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: TextOrBone(
                  title,
                  last: 0.5,
                  style: context.type.display.copyWith(color: c.textPrimary, height: 1.1),
                ),
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: NewsSpace.s2),
                Text(
                  text,
                  style: context.type.bodyL.copyWith(color: c.textSecondary, height: 1.45),
                ),
              ],
            ],
          ),
        ),
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: NewsSpace.s4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
              child: Row(
                children: [
                  for (final k in children)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NewsChip(k.name, onTap: () => context.push(k.path)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AuthorHead extends StatelessWidget {
  const _AuthorHead(this.author);

  final PublicAuthor? author;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final type = context.type;
    final a = author;
    return Padding(
      padding: const EdgeInsets.fromLTRB(NewsSpace.s5, NewsSpace.s4, NewsSpace.s5, NewsSpace.s6),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 112,
            child: ClipOval(
              child: a != null && a.avatar == null
                  ? Initial(a.name, size: 112)
                  : NewsPicture(a?.avatar),
            ),
          ),
          const SizedBox(height: NewsSpace.s4),
          Semantics(
            header: true,
            child: TextOrBone(
              a?.name,
              last: 0.5,
              align: TextAlign.center,
              style: type.headlineL.copyWith(color: c.textPrimary),
            ),
          ),
          if (a == null || a.title.isNotEmpty)
            TextOrBone(
              a?.title,
              last: 0.4,
              align: TextAlign.center,
              style: type.label.copyWith(color: c.textSecondary),
            ),
          if (a != null && a.bio.isNotEmpty) ...[
            const SizedBox(height: NewsSpace.s4),
            Text(
              a.bio,
              textAlign: TextAlign.center,
              style: type.bodyL.copyWith(color: c.textPrimary, height: 1.5),
            ),
          ],
          if (a != null && a.expertise.isNotEmpty) ...[
            const SizedBox(height: NewsSpace.s4),
            Text(
              a.expertise.join('  ·  '),
              textAlign: TextAlign.center,
              style: type.label.copyWith(color: c.textSecondary),
            ),
          ],
          if (a != null)
            for (final link in a.links)
              Pressable(
                link: true,
                onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NewsIcon(NewsIcons.link2, size: 16, color: c.link),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          Uri.parse(link).host,
                          style: type.label.copyWith(color: c.link),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Someone without a photograph.
class Initial extends StatelessWidget {
  const Initial(this.name, {super.key, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    color: context.colors.surfaceSunken,
    alignment: Alignment.center,
    child: ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: Text(
          name.isEmpty ? '' : name.characters.first.toUpperCase(),
          style: context.type.headlineM.copyWith(
            fontSize: size * 0.42,
            height: 1,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    ),
  );
}
