import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart';

import '../../core/network/images.dart';
import '../tokens/blurhash.dart';
import '../tokens/theme.dart';
import 'skeleton.dart';

/// A picture that never moves the page: its box is fixed by the layout, filled with its own colour, then its blur,
/// then itself. Decoded at the size it is shown.
class NewsPicture extends ConsumerWidget {
  const NewsPicture(this.image, {super.key, this.semantic, this.fit = BoxFit.cover, this.align});

  /// Null draws the bone of a picture.
  final PublicImage? image;

  /// What a screen reader says. Null: decoration, the headline already says it.
  final String? semantic;
  final BoxFit fit;
  final Alignment? align;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picture = image;
    if (picture == null) return const Bone.fill();
    final color = colorOf(picture.color) ?? context.colors.surfaceSunken;
    ref.watch(picturesProvider);
    return Semantics(
      image: semantic != null,
      label: semantic,
      excludeSemantics: semantic == null,
      child: ColoredBox(
        color: color,
        child: LayoutBuilder(
          builder: (context, box) {
            final ratio = MediaQuery.devicePixelRatioOf(context);
            final width = box.maxWidth.isFinite ? box.maxWidth : MediaQuery.sizeOf(context).width;
            final height = box.maxHeight.isFinite ? box.maxHeight : 0.0;
            // Covering a tall box with a wide picture needs more pixels than the box is wide.
            final natural = picture.width != null && picture.height != null
                ? picture.width! / picture.height!
                : 1.0;
            final needed =
                (fit == BoxFit.cover && height > 0 && width / height < natural
                    ? height * natural
                    : width) *
                ratio;
            final url = ref.read(picturesProvider.notifier).url(picture, needed);
            if (url.isEmpty) return const SizedBox.expand();
            return Stack(
              fit: StackFit.expand,
              children: [
                if (picture.blurhash.isNotEmpty) BlurhashView(picture.blurhash),
                Image(
                  image: ResizeImage(
                    ref.watch(pictureLoaderProvider)(url),
                    width: needed.ceil(),
                    policy: ResizeImagePolicy.fit,
                  ),
                  fit: fit,
                  alignment: align ?? focal(picture),
                  excludeFromSemantics: true,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                  frameBuilder: (context, child, frame, now) => now || context.still
                      ? child
                      : AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          child: child,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Alignment focal(PublicImage p) => p.focal.length == 2
      ? Alignment(p.focal[0] / 500 - 1, p.focal[1] / 500 - 1)
      : Alignment.center;
}

Color? colorOf(String hex) => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)
    ? Color(0xFF000000 | int.parse(hex.substring(1), radix: 16))
    : null;

class BlurhashView extends StatefulWidget {
  const BlurhashView(this.hash, {super.key});

  final String hash;

  @override
  State<BlurhashView> createState() => _BlurhashViewState();
}

class _BlurhashViewState extends State<BlurhashView> {
  static const _size = 24;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    unawaited(_decode());
  }

  @override
  void didUpdateWidget(BlurhashView old) {
    super.didUpdateWidget(old);
    if (old.hash != widget.hash) unawaited(_decode());
  }

  Future<void> _decode() async {
    final pixels = decodeBlurhash(widget.hash, _size, _size);
    if (pixels == null) return;
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(pixels, _size, _size, ui.PixelFormat.rgba8888, done.complete);
    final image = await done.future;
    if (!mounted) return image.dispose();
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _image == null
      ? const SizedBox.expand()
      : RawImage(image: _image, fit: BoxFit.fill, filterQuality: FilterQuality.medium);
}
