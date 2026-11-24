import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/models.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/picture.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/tokens/theme.dart';
import '../../ui/components/basics.dart';

/// Top stories side by side. The picture drifts a little slower than its card; the next one always peeks in.
class TopStories extends StatefulWidget {
  const TopStories({super.key, required this.stories, required this.open});

  final List<Story?> stories;
  final OpenStory open;

  @override
  State<TopStories> createState() => _TopStoriesState();
}

class _TopStoriesState extends State<TopStories> {
  late PageController _pages;
  double? _fraction;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    final fraction = width < 600 ? 0.84 : 0.46;
    if (_fraction != fraction) {
      if (_fraction != null) _pages.dispose();
      _fraction = fraction;
      _pages = PageController(viewportFraction: fraction);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(10) / 10;
    return SizedBox(
      height: 356 * scale.clamp(1, 1.5),
      child: PageView.builder(
        controller: _pages,
        padEnds: false,
        itemCount: widget.stories.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(left: i == 0 ? NewsSpace.s5 : NewsSpace.s3),
          child: _TopCard(
            widget.stories[i],
            number: i + 1,
            open: widget.open,
            pages: _pages,
            index: i,
          ),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard(
    this.story, {
    required this.number,
    required this.open,
    required this.pages,
    required this.index,
  });

  final Story? story;
  final int number;
  final OpenStory open;
  final PageController pages;
  final int index;

  @override
  Widget build(BuildContext context) {
    final story = this.story;
    final tag = story == null ? null : 'top-${story.id}';
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(NewsRadius.xl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (story == null)
            const Bone.fill()
          else
            AnimatedBuilder(
              animation: pages,
              builder: (context, child) {
                final page = pages.hasClients && pages.position.haveDimensions ? pages.page! : 0.0;
                final drift = context.still ? 0.0 : (index - page).clamp(-1.0, 1.0) * 26;
                return Transform.translate(
                  offset: Offset(-drift, 0),
                  child: Transform.scale(scale: 1.12, child: child),
                );
              },
              child: Hero(tag: tag!, child: NewsPicture(story.image)),
            ),
          if (story != null) ...[
            const DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
            Positioned(
              left: NewsSpace.s5,
              right: NewsSpace.s5,
              bottom: NewsSpace.s5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      '$number',
                      style: context.type.display.copyWith(
                        color: OverMedia.ink,
                        fontSize: 60,
                        height: 0.86,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  const SizedBox(width: NewsSpace.s4),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Kicker(story, onMedia: true),
                        const SizedBox(height: 4),
                        Text(
                          story.headline,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.headlineM.copyWith(
                            color: OverMedia.ink,
                            fontSize: 21,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
    return story == null
        ? card
        : Pressable(
            link: true,
            label: '$number. ${story.headline}',
            onTap: () => open(story, heroTag: tag),
            child: card,
          );
  }
}
