import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A player without a decoder: counts what is alive.
class FakeVideo extends VideoPlayerPlatform {
  static FakeVideo install() {
    final fake = FakeVideo();
    VideoPlayerPlatform.instance = fake;
    return current = fake;
  }

  static FakeVideo current = FakeVideo();

  int _next = 0;
  final alive = <int>{};
  final playing = <int>{};
  final created = <String>[];
  int most = 0;
  bool fail = false;
  final _events = <int, StreamController<VideoEvent>>{};

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _next++;
    alive.add(id);
    created.add(options.dataSource.uri ?? '');
    if (alive.length > most) most = alive.length;
    _events[id] = StreamController<VideoEvent>.broadcast();
    scheduleMicrotask(() {
      final events = _events[id];
      if (events == null || events.isClosed) return;
      Timer(Duration.zero, () {
        if (events.isClosed) return;
        if (fail) return events.addError(Exception('no'));
        events.add(
          VideoEvent(
            eventType: VideoEventType.initialized,
            size: const Size(720, 1280),
            duration: const Duration(seconds: 12),
          ),
        );
      });
    });
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;
  @override
  Future<void> dispose(int playerId) async {
    alive.remove(playerId);
    playing.remove(playerId);
    await _events.remove(playerId)?.close();
  }

  @override
  Future<void> play(int playerId) async => playing.add(playerId);
  @override
  Future<void> pause(int playerId) async => playing.remove(playerId);
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => const Duration(seconds: 4);
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox.expand();
}

VideoPlayerController networkVideo(String url) => VideoPlayerController.networkUrl(Uri.parse(url));
