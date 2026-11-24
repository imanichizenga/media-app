import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

typedef MakeController = VideoPlayerController Function(String url);

VideoPlayerController networkController(String url) => VideoPlayerController.networkUrl(
  Uri.parse(url),
  videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
);

/// At most three videos exist: the one before, the one shown, the one after. The next is made ready, which fetches
/// its playlist and first segment; everything else is let go at once.
class ShortsPool extends ChangeNotifier {
  ShortsPool({required this.urls, this.make = networkController, this.autoplay = true});

  final List<String> Function() urls;
  final MakeController make;
  bool autoplay;

  static const size = 3;

  final _live = <int, VideoPlayerController>{};
  final _failed = <int>{};
  int _at = -1;
  bool _muted = true;
  bool _awake = true;
  bool _held = false;
  bool _gone = false;

  bool get muted => _muted;
  bool get held => _held;
  int get alive => _live.length;
  VideoPlayerController? at(int i) => switch (_live[i]) {
    final c? when c.value.isInitialized => c,
    _ => null,
  };
  bool failed(int i) => _failed.contains(i);

  Future<void> show(int index) async {
    _at = index;
    _held = !autoplay;
    final list = urls();
    final wanted = {
      for (final i in [index - 1, index, index + 1])
        if (i >= 0 && i < list.length) i,
    };
    for (final i in _live.keys.where((i) => !wanted.contains(i)).toList()) {
      unawaited(_live.remove(i)!.dispose());
    }
    for (final i in _live.keys) {
      if (i != index) unawaited(_live[i]!.pause());
    }
    notifyListeners();
    await _ready(index);
    _play();
    if (index + 1 < list.length) await _ready(index + 1);
  }

  Future<void> _ready(int i) async {
    final list = urls();
    if (_gone || i >= list.length || _live.containsKey(i) || list[i].isEmpty) return;
    final controller = make(list[i]);
    _live[i] = controller;
    _failed.remove(i);
    try {
      await controller.initialize();
      if (_live[i] != controller) return; // let go meanwhile
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
    } on Object {
      if (_live[i] == controller) {
        _live.remove(i);
        _failed.add(i);
      }
      unawaited(controller.dispose());
    }
    if (!_gone) notifyListeners();
  }

  void _play() {
    if (_awake && !_held && !_gone) unawaited(_live[_at]?.play());
  }

  Future<void> retry() async {
    _failed.remove(_at);
    await show(_at);
  }

  void toggleMute() {
    _muted = !_muted;
    for (final c in _live.values) {
      unawaited(c.setVolume(_muted ? 0 : 1));
    }
    notifyListeners();
  }

  void toggleHold() {
    _held = !_held;
    _held ? unawaited(_live[_at]?.pause()) : _play();
    notifyListeners();
  }

  /// Off the screen, or the app in the background.
  void awake(bool value) {
    if (_awake == value) return;
    _awake = value;
    value ? _play() : unawaited(_live[_at]?.pause());
  }

  @override
  void dispose() {
    _gone = true;
    for (final c in _live.values) {
      unawaited(c.dispose());
    }
    _live.clear();
    super.dispose();
  }
}
