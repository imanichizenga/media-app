import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' hide Card;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../app/window.dart';
import '../../core/models.dart';
import '../../core/network/failures.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/adaptive/tops.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/picture.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../content/feeds.dart';
import '../content/list_screen.dart' show Initial;

const categoryIcons = <String, NewsIconData>{
  'newspaper': NewsIcons.newspaper,
  'landmark': NewsIcons.landmark,
  'trending-up': NewsIcons.trendingUp,
  'trophy': NewsIcons.trophy,
  'heart-pulse': NewsIcons.heartPulse,
  'graduation-cap': NewsIcons.graduationCap,
  'cpu': NewsIcons.cpu,
  'music': NewsIcons.music,
  'leaf': NewsIcons.leaf,
  'globe': NewsIcons.globe,
  'earth': NewsIcons.earth,
  'message-square-quote': NewsIcons.messageSquareQuote,
};

/// Everything there is, by section and by writer. Searching arrives in M8, and its field with it.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with GoesToTop {
  @override
  Widget build(BuildContext context) {
    final nav = ref.watch(navigationProvider);
    final home = ref.watch(homeFeedProvider).value?.value;
    final s = Strings.of(context);
    final items = nav.value?.value;
    // A section shows its own newest picture.
    PublicImage? face(NavigationItem? n) {
      if (n == null || home == null) return null;
      final ids = {n.id, for (final k in n.children) k.id};
      return [
            for (final x in home.sections)
              if (x.category.id == n.id) ...x.results,
            ...home.latest,
            ...home.videos,
            ...home.lead,
          ]
          .where(
            (r) =>
                r.image != null &&
                !r.isSensitive &&
                (ids.contains(r.category.id) ||
                    home.sections.any((s) => s.category.id == n.id && s.results.contains(r))),
          )
          .firstOrNull
          ?.image;
    }

    final people = <String, CardByline>{
      for (final Story x in [...?home?.lead, ...?home?.latest])
        for (final a in x.authors) a.id: a,
    }.values.take(12).toList();
    final columns = switch (windowOf(context)) {
      WindowClass.compact => 2,
      WindowClass.medium => 3,
      WindowClass.expanded => 4,
    };
    final scale = (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(1.0, 2.0);
    return Scaffold(
      body: Shimmer(
        child: NewsScroll(
          controller: scroll,
          edge: MediaQuery.paddingOf(context).top + PlaceBar.extent,
          onRefresh: () => Future.wait([
            ref.read(navigationProvider.notifier).refresh(),
            ref.read(homeFeedProvider.notifier).refresh(),
          ]),
          header: [PlaceBar(s.navExplore)],
          slivers: [
            if (nav.hasError && items == null)
              SliverToBoxAdapter(
                child: Designed.failure(
                  context,
                  nav.error!,
                  retry: () => ref.invalidate(navigationProvider),
                  saved: nav.error is OfflineFailure ? () => const SavedRoute().go(context) : null,
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: NewsSpace.s3,
                    crossAxisSpacing: NewsSpace.s3,
                    mainAxisExtent: 112 + 24 * scale,
                  ),
                  itemCount: items?.length ?? 8,
                  itemBuilder: (context, i) => CategoryTile(items?[i], image: face(items?[i])),
                ),
              ),
              if (people.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: NewsSpace.s10)),
                SliverToBoxAdapter(child: SectionHead(s.journalists)),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: NewsSpace.s5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final a in people)
                          Padding(
                            padding: const EdgeInsets.only(right: NewsSpace.s4),
                            child: _Person(a),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile(this.item, {super.key, this.image});

  final NavigationItem? item;
  final PublicImage? image;

  @override
  Widget build(BuildContext context) {
    final n = item;
    final c = context.colors;
    if (n == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(NewsRadius.lg),
        child: const Bone.fill(),
      );
    }
    final ink = image == null ? c.textPrimary : OverMedia.ink;
    return Pressable(
      link: true,
      label: n.name,
      scale: 0.97,
      onTap: () => openPath(context, n.path),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NewsRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null) ...[
              NewsPicture(image),
              const DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
            ] else
              ColoredBox(color: c.surfaceSunken),
            Padding(
              padding: const EdgeInsets.all(NewsSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  NewsIcon(categoryIcons[n.icon] ?? NewsIcons.newspaper, size: 22, color: ink),
                  const SizedBox(height: 6),
                  Text(
                    n.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.headlineS.copyWith(color: ink, height: 1.15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person(this.author);

  final CardByline author;

  @override
  Widget build(BuildContext context) => Pressable(
    link: true,
    label: Strings.of(context).storiesBy(author.name),
    onTap: () => openPath(context, author.path),
    scale: 0.95,
    child: SizedBox(
      width: 92,
      child: Column(
        children: [
          ClipOval(child: SizedBox.square(dimension: 84, child: Initial(author.name, size: 84))),
          const SizedBox(height: NewsSpace.s2),
          Text(
            author.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.type.caption.copyWith(color: context.colors.textPrimary, height: 1.25),
          ),
        ],
      ),
    ),
  );
}
