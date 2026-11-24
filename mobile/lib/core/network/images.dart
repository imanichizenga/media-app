import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:news_api_client/news_api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../providers.dart';

part 'images.g.dart';

/// Pictures seen: bounded, and gone after a month. Pictures of saved articles: kept until the article is removed.
final seenPictures = CacheManager(
  Config('seen', stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 600),
);
final savedPictures = CacheManager(
  Config('saved', stalePeriod: const Duration(days: 3650), maxNrOfCacheObjects: 20000),
);

typedef PictureLoader = ImageProvider<Object> Function(String url);

/// Replaced in tests, which have no network.
@Riverpod(keepAlive: true)
PictureLoader pictureLoader(Ref ref) => KeptPicture.new;

/// From the saved store, then the seen one, then the network.
@immutable
class KeptPicture extends ImageProvider<KeptPicture> {
  const KeptPicture(this.url);

  final String url;

  @override
  Future<KeptPicture> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(KeptPicture key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1, debugLabel: url);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final saved = await savedPictures.getFileFromCache(url);
    final file = saved?.file ?? await seenPictures.getSingleFile(url);
    return decode(await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes()));
  }

  @override
  bool operator ==(Object other) => other is KeptPicture && other.url == url;
  @override
  int get hashCode => url.hashCode;
}

/// Where one picture lives at the width it is shown: the CDN's nearest variant, one size down to save data.
@Riverpod(keepAlive: true)
class Pictures extends _$Pictures {
  @override
  ({String base, bool saver}) build() =>
      (base: ref.watch(mediaBaseProvider), saver: !ref.watch(autoplayProvider));

  String url(PublicImage image, double pixels) {
    final widths = image.widths;
    if (widths.isEmpty) return '';
    var i = widths.indexWhere((w) => w >= pixels);
    if (i < 0) i = widths.length - 1;
    if (state.saver && i > 0) i--;
    return address('${image.base_}${widths[i]}.webp');
  }

  String address(String key) => key.isEmpty || key.startsWith(RegExp('https?:|/'))
      ? key.startsWith('/')
            ? '${state.base}$key'
            : key
      : '${state.base}/$key';
}
