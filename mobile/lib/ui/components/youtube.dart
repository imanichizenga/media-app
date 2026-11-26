import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_api_client/news_api_client.dart' show PublicImage;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../l10n/gen/strings.dart';
import '../tokens/theme.dart';
import 'basics.dart';
import 'picture.dart';
import 'player.dart';

/// A still until it is tapped: nothing of YouTube's is loaded before that. Then its private player, and only that.
class YoutubeFacade extends StatefulWidget {
  const YoutubeFacade({
    super.key,
    required this.videoId,
    required this.title,
    this.image,
    this.start = 0,
    this.vertical = false,
    this.enabled = true,
    this.radius = NewsRadius.lg,
  });

  final String videoId;
  final String title;
  final PublicImage? image;
  final int start;
  final bool vertical;

  /// The remote kill switch. Off: the still, without a button that does nothing.
  final bool enabled;
  final double radius;

  static Uri address(String id, int start) => Uri.https('www.youtube-nocookie.com', '/embed/$id', {
    'autoplay': '1',
    'playsinline': '1',
    'rel': '0',
    if (start > 0) 'start': '$start',
  });

  /// The player and nothing else: no link in it can lead anywhere.
  static bool allowed(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'www.youtube-nocookie.com' &&
        uri.path.startsWith('/embed/');
  }

  @override
  State<YoutubeFacade> createState() => _YoutubeFacadeState();
}

class _YoutubeFacadeState extends State<YoutubeFacade> {
  WebViewController? _web;

  void _play() => setState(
    () => _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(OverMedia.ground)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) => r.isMainFrame && !YoutubeFacade.allowed(r.url)
              ? NavigationDecision.prevent
              : NavigationDecision.navigate,
        ),
      )
      ..loadRequest(YoutubeFacade.address(widget.videoId, widget.start)),
  );

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AspectRatio(
        aspectRatio: widget.vertical ? 9 / 16 : 16 / 9,
        child: _web != null
            ? WebViewWidget(
                controller: _web!,
                gestureRecognizers: const {
                  Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
                },
              )
            : Pressable(
                onTap: widget.enabled ? _play : null,
                label: '${s.youtubePlay}: ${widget.title}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.image != null)
                      NewsPicture(widget.image)
                    else
                      const ColoredBox(color: OverMedia.ground),
                    const DecoratedBox(decoration: BoxDecoration(gradient: OverMedia.fade)),
                    if (widget.enabled) const Center(child: BigPlay()),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YouTube',
                            style: context.type.eyebrow.copyWith(color: OverMedia.soft),
                          ),
                          if (widget.title.isNotEmpty)
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.type.label.copyWith(color: OverMedia.ink),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
