import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../app/window.dart';
import '../../core/models.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/adaptive/tops.dart';
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
class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key, required this.feed, required this.path});

  final FeedKey feed;
  final String path;

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> with GoesToTop {
  FeedKey get feed => widget.feed;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedProvider(feed));
    final about = state.value?.about;
    final c = context.colors;
    // An address that nothing answers to may have moved.
    if (state.hasError && state.value == null) {
      ref.listen(movedProvider(widget.path), (_, next) {
        if (next.value case final target?) context.replace(target);
      });
    }
    // The sections are known before their stories are: the title and what is under it never arrive late.
    final known = sectionOf(ref, feed);
    final title =
        known?.name ??
        about?.category?.name ??
        about?.tag?.name ??
        about?.story?.title ??
        about?.author?.name;
    final person = feed.kind == FeedKind.author;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.bg),
      child: Scaffold(
        body: Shimmer(
          child: FeedPager(
            feed: feed,
            child: NewsScroll(
              controller: scroll,
              edge: MediaQuery.paddingOf(context).top + PlaceBar.extent,
              onRefresh: () => ref.read(feedProvider(feed).notifier).refresh(),
              header: [
                PlaceBar(
                  title ?? '',
                  onBack: () => Navigator.of(context).canPop()
                      ? Navigator.of(context).pop()
                      : const HomeRoute().go(context),
                ),
              ],
              slivers: [
                if (person)
                  SliverToBoxAdapter(child: _AuthorHead(about?.author))
                else
                  SliverToBoxAdapter(
                    child: FeedAboutHead(
                      text: about?.category?.description ?? about?.story?.summary ?? '',
                      children: about?.category?.children ?? known?.children ?? const [],
                    ),
                  ),
                ...FeedBody.slivers(context, ref, feed: feed, place: 'list'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the navigation already knows of a category.
NavigationItem? sectionOf(WidgetRef ref, FeedKey feed) => feed.kind != FeedKind.category
    ? null
    : ref.watch(navigationProvider).value?.value.where((n) => n.slug == feed.slug).firstOrNull;

/// Asks for the next page before its end is seen.
class FeedPager extends ConsumerWidget {
  const FeedPager({super.key, required this.feed, required this.child});

  final FeedKey feed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => NotificationListener<ScrollNotification>(
    onNotification: (n) {
      if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 1600) {
        unawaited(ref.read(feedProvider(feed).notifier).loadMore());
      }
      return false;
    },
    child: child,
  );
}

/// The stories of a list: one over the width, then the rest.
abstract final class FeedBody {
  static List<Widget> slivers(
    BuildContext context,
    WidgetRef ref, {
    required FeedKey feed,
    required String place,
  }) {
    final state = ref.watch(feedProvider(feed));
    final first = state.value?.stories.firstOrNull;
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: feed.kind.name);
    final cover =
        (feed.kind == FeedKind.category || feed.kind == FeedKind.story) &&
        windowOf(context) == WindowClass.compact &&
        (state.value == null ? state.isLoading : first?.image != null);
    return [
      if (cover) ...[
        SliverToBoxAdapter(
          child: CoverCard(first, open: open, place: place),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s2)),
      ],
      ...feedSlivers(
        context,
        ref,
        feed: feed,
        open: open,
        place: place,
        skip: cover && first != null ? 1 : 0,
      ),
    ];
  }
}

/// What a list is about, and its parts.
class FeedAboutHead extends StatelessWidget {
  const FeedAboutHead({super.key, this.text = '', required this.children});

  final String text;
  final List<PublicCategory> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (text.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NewsSpace.s5,
            NewsSpace.s1,
            NewsSpace.s5,
            NewsSpace.s3,
          ),
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.type.bodyM.copyWith(color: context.colors.textSecondary, height: 1.4),
          ),
        ),
      if (children.isNotEmpty)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            NewsSpace.s5,
            NewsSpace.s2,
            NewsSpace.s5,
            NewsSpace.s3,
          ),
          child: Row(
            children: [
              for (final k in children)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: NewsChip(k.name, onTap: () => openPath(context, k.path)),
                ),
            ],
          ),
        ),
    ],
  );
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
      padding: const EdgeInsets.fromLTRB(NewsSpace.s5, NewsSpace.s2, NewsSpace.s5, NewsSpace.s4),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 88,
            child: ClipOval(
              child: a != null && a.avatar == null
                  ? Initial(a.name, size: 88)
                  : NewsPicture(a?.avatar),
            ),
          ),
          const SizedBox(height: NewsSpace.s4),
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
