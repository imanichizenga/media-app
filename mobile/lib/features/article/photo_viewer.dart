import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' show PublicImage;
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/picture.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';

class Photo {
  const Photo(this.image, {required this.alt, this.caption = '', this.credit = ''});

  final PublicImage image;
  final String alt;
  final String caption;
  final String credit;
}

Future<void> showPhotos(BuildContext context, List<Photo> photos, {int at = 0}) =>
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: OverMedia.clear,
        transitionDuration: NewsMotion.slow,
        pageBuilder: (_, _, _) => PhotoViewer(photos: photos, at: at),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );

/// Pictures alone, on black. Pinch or double-tap to look closer, pull down to leave.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.photos, this.at = 0});

  final List<Photo> photos;
  final int at;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late final _pages = PageController(initialPage: widget.at);
  late int _at = widget.at;
  bool _zoomed = false;
  bool _words = true;
  double _pull = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final photo = widget.photos[_at];
    final many = widget.photos.length > 1;
    final away = (_pull.abs() / 400).clamp(0.0, 0.7);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(OverMedia.ground),
      child: Material(
        color: OverMedia.ground.withValues(alpha: 1 - away),
        child: GestureDetector(
          onTap: () => setState(() => _words = !_words),
          onVerticalDragUpdate: _zoomed ? null : (d) => setState(() => _pull += d.delta.dy),
          onVerticalDragEnd: _zoomed
              ? null
              : (d) {
                  if (_pull.abs() > 120 || (d.primaryVelocity ?? 0).abs() > 900) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _pull = 0);
                  }
                },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, _pull),
                child: PageView.builder(
                  controller: _pages,
                  physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
                  itemCount: widget.photos.length,
                  onPageChanged: (i) => setState(() => _at = i),
                  itemBuilder: (_, i) => _Zoomable(
                    onZoom: (z) => setState(() => _zoomed = z),
                    child: NewsPicture(
                      widget.photos[i].image,
                      semantic: widget.photos[i].alt,
                      fit: BoxFit.contain,
                      align: Alignment.center,
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _words && !_zoomed ? 1 : 0,
                duration: NewsMotion.base,
                child: IgnorePointer(
                  ignoring: !_words || _zoomed,
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              RoundButton(
                                NewsIcons.x,
                                label: s.close,
                                overMedia: true,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              if (many)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Semantics(
                                    label: s.imageOf(_at + 1, widget.photos.length),
                                    excludeSemantics: true,
                                    child: Text(
                                      '${_at + 1} / ${widget.photos.length}',
                                      style: context.type.label.copyWith(
                                        color: OverMedia.ink,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (photo.caption.isNotEmpty || photo.credit.isNotEmpty)
                        _Caption(photo, key: ValueKey(_at)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Zoomable extends StatefulWidget {
  const _Zoomable({required this.child, required this.onZoom});

  final Widget child;
  final ValueChanged<bool> onZoom;

  @override
  State<_Zoomable> createState() => _ZoomableState();
}

class _ZoomableState extends State<_Zoomable> {
  final _view = TransformationController();
  Offset _tap = Offset.zero;
  bool _close = false;

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  void _report() {
    final close = _view.value.getMaxScaleOnAxis() > 1.02;
    if (close != _close) setState(() => _close = close);
    widget.onZoom(close);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTapDown: (d) => _tap = d.localPosition,
    onDoubleTap: () {
      final zoomed = _view.value.getMaxScaleOnAxis() > 1.02;
      _view.value = zoomed
          ? Matrix4.identity()
          : (Matrix4.identity()
              ..translateByDouble(-_tap.dx * 1.5, -_tap.dy * 1.5, 0, 1)
              ..scaleByDouble(2.5, 2.5, 1, 1));
      _report();
    },
    child: InteractiveViewer(
      transformationController: _view,
      maxScale: 5,
      // At rest a finger turns the page or pulls the picture away.
      panEnabled: _close,
      onInteractionEnd: (_) => _report(),
      child: widget.child,
    ),
  );
}

/// Two lines at first, all of it when asked.
class _Caption extends StatefulWidget {
  const _Caption(this.photo, {super.key});

  final Photo photo;

  @override
  State<_Caption> createState() => _CaptionState();
}

class _CaptionState extends State<_Caption> {
  bool _whole = false;

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    return Semantics(
      expanded: _whole,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _whole = !_whole),
        child: AnimatedSize(
          duration: context.still ? const Duration(milliseconds: 1) : NewsMotion.base,
          curve: NewsMotion.standard,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
            decoration: const BoxDecoration(
              color: OverMedia.pill,
              borderRadius: BorderRadius.vertical(top: Radius.circular(NewsRadius.xl)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.paddingOf(context).bottom + 16),
            child: SingleChildScrollView(
              physics: _whole ? null : const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.caption.isNotEmpty)
                    Text(
                      photo.caption,
                      maxLines: _whole ? null : 2,
                      overflow: _whole ? null : TextOverflow.ellipsis,
                      style: context.type.bodyM.copyWith(color: OverMedia.ink),
                    ),
                  if (photo.credit.isNotEmpty)
                    Text(photo.credit, style: context.type.caption.copyWith(color: OverMedia.soft)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
