import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' show PublicImage, PublicVideo, RelatedTarget;
import 'package:news_content/news_content.dart' hide TableRow;
import 'package:news_content/news_content.dart' as content show TableRow;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/config/app_config.dart';
import '../../core/format/format.dart';
import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/picture.dart';
import '../../ui/components/player.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/components/youtube.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import 'inline.dart';
import 'photo_viewer.dart';

/// What the blocks of a body refer to: files by id, and where related links point.
class BodyContext {
  BodyContext({required Map<String, Map<String, dynamic>> assets, required this.links})
    : _assets = assets;

  final Map<String, Map<String, dynamic>> _assets;
  final Map<String, RelatedTarget> links;
  final _read = <String, Object?>{};

  Object? _asset(String id) => _read.putIfAbsent(id, () {
    final raw = _assets[id];
    try {
      return switch (raw?['kind']) {
        'image' => PublicImage.fromJson(raw!),
        'video' => PublicVideo.fromJson(raw!),
        _ => null,
      };
    } on Object {
      return null;
    }
  });

  PublicImage? image(String id) => switch (_asset(id)) {
    final PublicImage i => i,
    _ => null,
  };
  PublicVideo? video(String id) => switch (_asset(id)) {
    final PublicVideo v => v,
    _ => null,
  };
}

const _gap = NewsSpace.s6;

/// Every block of the content schema, drawn natively. A block from the future says so and nothing more.
class ArticleBody extends StatelessWidget {
  const ArticleBody({super.key, required this.document, required this.data});

  /// Null: the same column in bones.
  final ContentDocument? document;
  final BodyContext? data;

  @override
  Widget build(BuildContext context) {
    final style = bodyStyle(context);
    if (document == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final lines in const [4, 5, 3, 4])
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: TextOrBone(null, style: style, lines: lines),
            ),
        ],
      );
    }
    final blocks = document!.blocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, block) in blocks.indexed)
          Padding(
            padding: EdgeInsets.only(
              // A heading belongs to what follows it.
              top: block is HeadingBlock && i > 0 ? NewsSpace.s3 : 0,
              bottom: block is HeadingBlock ? NewsSpace.s3 : _gap,
            ),
            child: BlockView(block, data: data!),
          ),
      ],
    );
  }
}

TextStyle bodyStyle(BuildContext context) =>
    context.type.bodyL.copyWith(color: context.colors.textPrimary);

class BlockView extends ConsumerWidget {
  const BlockView(this.block, {super.key, required this.data});

  final Object block;
  final BodyContext data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final type = context.type;
    final s = Strings.of(context);
    final body = bodyStyle(context);
    switch (block) {
      case ParagraphBlock(:final content):
        return InlineText(content, style: body);
      case HeadingBlock(:final level, :final content):
        return Semantics(
          header: true,
          child: InlineText(
            content,
            style: switch (level) {
              2 => type.headlineM.copyWith(color: c.textPrimary, fontSize: 26, height: 1.2),
              3 => type.headlineS.copyWith(color: c.textPrimary, fontSize: 21, height: 1.25),
              _ => type.title.copyWith(color: c.textPrimary, fontSize: 18),
            },
          ),
        );
      case ListBlock(:final ordered, :final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, item) in items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: NewsSpace.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 28),
                      child: Text(
                        ordered ? '${i + 1}.' : '•',
                        style: body.copyWith(color: c.textSecondary),
                      ),
                    ),
                    Expanded(child: InlineText(item.content, style: body)),
                  ],
                ),
              ),
          ],
        );
      case ImageBlock(:final asset, :final alt, :final caption, :final credit, :final sensitive):
        final image = data.image(asset);
        if (image == null) return const SizedBox.shrink();
        return _Figure(
          photos: [
            Photo(image, alt: alt, caption: plain(caption), credit: credit ?? image.credit),
          ],
          sensitive: sensitive ?? false,
        );
      case GalleryBlock(:final items):
        final photos = [
          for (final item in items)
            if (data.image(item.asset) case final image?)
              Photo(
                image,
                alt: item.alt,
                caption: plain(item.caption),
                credit: item.credit ?? image.credit,
              ),
        ];
        return photos.isEmpty ? const SizedBox.shrink() : _Gallery(photos);
      case VideoBlock(:final asset, :final caption, :final credit, :final sensitive):
        final video = data.video(asset);
        if (video == null) return const SizedBox.shrink();
        final player = NewsPlayer(
          hls: video.hls,
          poster: video.poster,
          color: video.color,
          label: plain(caption).isEmpty ? video.alt : plain(caption),
          ratio: ratioOf(video),
          length: video.durationMs == null ? null : Duration(milliseconds: video.durationMs!),
        );
        return _Captioned(
          caption: plain(caption),
          credit: credit ?? video.credit,
          child: sensitive ?? false
              ? _Reveal(ratio: ratioOf(video), child: player)
              : player,
        );
      case YoutubeBlock(:final videoId, :final title, :final start, :final vertical):
        return YoutubeFacade(
          videoId: videoId,
          title: title ?? '',
          start: start ?? 0,
          vertical: vertical ?? false,
          enabled: ref.watch(flagsProvider).youtube,
        );
      case QuoteBlock(:final content, :final attribution):
        return Container(
          padding: const EdgeInsets.only(left: NewsSpace.s5),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: c.borderStrong, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InlineText(content, style: type.serif.copyWith(color: c.textPrimary)),
              if (attribution != null && attribution.isNotEmpty) ...[
                const SizedBox(height: NewsSpace.s2),
                Text(attribution, style: type.label.copyWith(color: c.textSecondary)),
              ],
            ],
          ),
        );
      case PullQuoteBlock(:final text, :final attribution):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
          child: Column(
            children: [
              Container(width: 40, height: 3, color: c.textPrimary),
              const SizedBox(height: NewsSpace.s5),
              Text(
                text,
                textAlign: TextAlign.center,
                style: type.headlineL.copyWith(color: c.textPrimary, fontSize: 28, height: 1.22),
              ),
              if (attribution != null && attribution.isNotEmpty) ...[
                const SizedBox(height: NewsSpace.s3),
                Text(
                  attribution,
                  textAlign: TextAlign.center,
                  style: type.label.copyWith(color: c.textSecondary),
                ),
              ],
              const SizedBox(height: NewsSpace.s5),
              Container(width: 40, height: 3, color: c.textPrimary),
            ],
          ),
        );
      case EmbedBlock(:final provider, :final url, :final author, :final text):
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (author != null && author.isNotEmpty) author,
                  switch (provider) {
                    EmbedProvider.x => 'X',
                    EmbedProvider.instagram => 'Instagram',
                    EmbedProvider.facebook => 'Facebook',
                    EmbedProvider.tiktok => 'TikTok',
                    EmbedProvider.unknown => Uri.tryParse(url)?.host ?? '',
                  },
                ].join('  ·  '),
                style: type.label.copyWith(color: c.textSecondary),
              ),
              if (text != null && text.isNotEmpty) ...[
                const SizedBox(height: NewsSpace.s2),
                Text(text, style: body.copyWith(fontSize: 17)),
              ],
              _Action(
                s.openPost,
                icon: NewsIcons.externalLink,
                onTap: () => follow(context, url),
              ),
            ],
          ),
        );
      case TableBlock(:final header, :final rows, :final caption):
        return _Table(header: header, rows: rows, caption: caption ?? '');
      case CalloutBlock(:final tone, :final title, :final content):
        final (icon, ink, ground) = switch (tone) {
          CalloutTone.warning => (NewsIcons.triangleAlert, c.warning, c.warningSoft),
          CalloutTone.success => (NewsIcons.circleCheck, c.success, c.successSoft),
          _ => (NewsIcons.info, c.textPrimary, c.surfaceSunken),
        };
        return Container(
          padding: const EdgeInsets.all(NewsSpace.s5),
          decoration: BoxDecoration(
            color: ground,
            borderRadius: BorderRadius.circular(NewsRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: NewsIcon(icon, size: 20, color: ink),
              ),
              const SizedBox(width: NewsSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(title, style: type.title.copyWith(color: ink)),
                      ),
                    InlineText(content, style: body.copyWith(fontSize: 17, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      case FactboxBlock(:final title, :final items):
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 28, height: 3, color: c.textPrimary),
              const SizedBox(height: NewsSpace.s3),
              Semantics(
                header: true,
                child: Text(title, style: type.headlineS.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(height: NewsSpace.s2),
              for (final (i, item) in items.indexed) ...[
                if (i > 0) Divider(color: c.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: NewsSpace.s3),
                  child: InlineText(item.content, style: body.copyWith(fontSize: 17, height: 1.5)),
                ),
              ],
            ],
          ),
        );
      case RelatedLinkBlock(:final title, :final post, :final url):
        final target = post == null ? null : data.links[post];
        final href = target?.path ?? url;
        if (href == null) return const SizedBox.shrink(); // no dead links
        return Pressable(
          link: true,
          onTap: () => target == null ? follow(context, href) : context.push(href),
          child: _Panel(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.readAlso.toUpperCase(),
                        style: type.eyebrow.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        target?.headline ?? title,
                        style: type.headlineS.copyWith(color: c.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: NewsSpace.s3),
                NewsIcon(NewsIcons.arrowRight, size: 20, color: c.textSecondary),
              ],
            ),
          ),
        );
      case PollBlock(:final question, :final options):
        // Read only until voting arrives (M4): the question and its answers, no button that does nothing.
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.poll.toUpperCase(), style: type.eyebrow.copyWith(color: c.textSecondary)),
              const SizedBox(height: 4),
              Text(question, style: type.headlineS.copyWith(color: c.textPrimary)),
              const SizedBox(height: NewsSpace.s3),
              for (final o in options)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: NewsSpace.s2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(NewsRadius.md),
                  ),
                  child: Text(o.label, style: type.bodyM.copyWith(color: c.textPrimary)),
                ),
            ],
          ),
        );
      case final LiveUpdateBlock update:
        return _LiveUpdate(update, data: data);
      default:
        return _Panel(
          child: Row(
            children: [
              NewsIcon(NewsIcons.info, size: 18, color: c.textSecondary),
              const SizedBox(width: NewsSpace.s3),
              Expanded(
                child: Text(s.unsupported, style: type.label.copyWith(color: c.textSecondary)),
              ),
            ],
          ),
        );
    }
  }
}

double ratioOf(PublicVideo v) => v.width != null && v.height != null && v.height! > 0
    ? (v.width! / v.height!).clamp(9 / 16, 21 / 9)
    : 16 / 9;

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(NewsSpace.s5),
    decoration: BoxDecoration(
      color: context.colors.surfaceSunken,
      borderRadius: BorderRadius.circular(NewsRadius.lg),
    ),
    child: child,
  );
}

class _Action extends StatelessWidget {
  const _Action(this.text, {required this.icon, required this.onTap});

  final String text;
  final NewsIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    link: true,
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(text, style: context.type.label.copyWith(color: context.colors.link)),
          ),
          const SizedBox(width: 6),
          NewsIcon(icon, size: 16, color: context.colors.link),
        ],
      ),
    ),
  );
}

class _Captioned extends StatelessWidget {
  const _Captioned({required this.caption, required this.credit, required this.child});

  final String caption;
  final String credit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (caption.isNotEmpty || credit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: NewsSpace.s2),
            child: Text.rich(
              TextSpan(
                children: [
                  if (caption.isNotEmpty) TextSpan(text: '$caption  '),
                  if (credit.isNotEmpty)
                    TextSpan(
                      text: credit,
                      style: TextStyle(color: c.textTertiary),
                    ),
                ],
              ),
              style: context.type.caption.copyWith(color: c.textSecondary, height: 1.4),
            ),
          ),
      ],
    );
  }
}

/// Editors marked it: the reader decides.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.ratio, required this.child});

  final double ratio;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => _open
      ? widget.child
      : AspectRatio(
          aspectRatio: widget.ratio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(NewsRadius.lg),
            child: SensitiveCover(
              onShow: () => setState(() => _open = true),
              child: IgnorePointer(child: ExcludeSemantics(child: widget.child)),
            ),
          ),
        );
}

class _Figure extends StatelessWidget {
  const _Figure({required this.photos, required this.sensitive});

  final List<Photo> photos;
  final bool sensitive;

  @override
  Widget build(BuildContext context) {
    final photo = photos.first;
    final image = photo.image;
    final ratio = image.width != null && image.height != null && image.height! > 0
        ? (image.width! / image.height!).clamp(0.75, 2.4)
        : 1.5;
    final picture = Pressable(
      onTap: () => showPhotos(context, photos),
      label: photo.alt,
      child: AspectRatio(
        aspectRatio: ratio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(NewsRadius.lg),
          child: NewsPicture(image),
        ),
      ),
    );
    return _Captioned(
      caption: photo.caption,
      credit: photo.credit,
      child: sensitive ? _Reveal(ratio: ratio, child: picture) : picture,
    );
  }
}

/// Swipe here, or open the pictures alone.
class _Gallery extends StatefulWidget {
  const _Gallery(this.photos);

  final List<Photo> photos;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pages = PageController(viewportFraction: 0.9);
  int _at = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = Strings.of(context);
    final photos = widget.photos;
    final photo = photos[_at];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: box.maxWidth * 0.9 * 0.72,
            child: PageView.builder(
              controller: _pages,
              padEnds: false,
              itemCount: photos.length,
              onPageChanged: (i) => setState(() => _at = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: NewsSpace.s2),
                child: Pressable(
                  onTap: () => showPhotos(context, photos, at: i),
                  label: '${s.imageOf(i + 1, photos.length)}. ${photos[i].alt}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(NewsRadius.lg),
                    child: NewsPicture(photos[i].image),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: NewsSpace.s2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                [photo.caption, photo.credit].where((t) => t.isNotEmpty).join('  '),
                style: context.type.caption.copyWith(color: c.textSecondary, height: 1.4),
              ),
            ),
            const SizedBox(width: NewsSpace.s3),
            ExcludeSemantics(
              child: Text(
                '${_at + 1} / ${photos.length}',
                style: context.type.caption.copyWith(
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.header, required this.rows, required this.caption});

  final bool header;
  final List<content.TableRow> rows;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final columns = rows.fold(0, (n, r) => r.cells.length > n ? r.cells.length : n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder(
              horizontalInside: BorderSide(color: c.border),
              top: BorderSide(color: c.textPrimary, width: 2),
              bottom: BorderSide(color: c.border),
            ),
            children: [
              for (final (r, row) in rows.indexed)
                TableRow(
                  children: [
                    for (var i = 0; i < columns; i++)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 20, 12),
                          child: i < row.cells.length
                              ? InlineText(
                                  row.cells[i].content,
                                  style: header && r == 0
                                      ? context.type.label.copyWith(color: c.textSecondary)
                                      : context.type.bodyM.copyWith(
                                          color: c.textPrimary,
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: NewsSpace.s2),
            child: Text(caption, style: context.type.caption.copyWith(color: c.textSecondary)),
          ),
      ],
    );
  }
}

/// One moment of a live blog, on its line.
class _LiveUpdate extends ConsumerWidget {
  const _LiveUpdate(this.update, {required this.data});

  final LiveUpdateBlock update;
  final BodyContext data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = Strings.of(context);
    final time = DateTime.tryParse(update.time);
    return Stack(
      children: [
        Positioned(
          left: 5,
          top: 10,
          bottom: -NewsSpace.s6,
          child: Container(width: 2, color: c.border),
        ),
        Positioned(
          left: 0,
          top: 5,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: c.bg,
              shape: BoxShape.circle,
              border: Border.all(color: c.textPrimary, width: 3),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  if (time != null)
                    Text(
                      ago(time, s, ref.watch(clockNowProvider)()),
                      style: context.type.label.copyWith(color: c.textPrimary),
                    ),
                  if (update.author != null && update.author!.isNotEmpty)
                    Text(
                      update.author!,
                      style: context.type.label.copyWith(color: c.textSecondary),
                    ),
                  if (update.pinned ?? false)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NewsIcon(NewsIcons.pin, size: 13, color: c.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          s.pinned,
                          style: context.type.label.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
              if (update.title != null && update.title!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Semantics(
                  header: true,
                  child: Text(
                    update.title!,
                    style: context.type.headlineS.copyWith(color: c.textPrimary),
                  ),
                ),
              ],
              for (final inner in update.blocks)
                Padding(
                  padding: const EdgeInsets.only(top: NewsSpace.s3),
                  child: BlockView(inner, data: data),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
