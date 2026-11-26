import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup.g.dart';

/// Tells Android, once, that the news is on the screen: the "time to full display" that the Play Console reports and
/// CI measures (support/scripts/mobile-perf.sh).
class Startup {
  static const _channel = MethodChannel('news/startup');
  bool _told = false;

  /// After the frame that shows it.
  void drawn() {
    if (_told || defaultTargetPlatform != TargetPlatform.android) return;
    _told = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_tell()));
  }

  Future<void> _tell() async {
    try {
      await _channel.invokeMethod<void>('fullyDrawn');
    } on PlatformException {
      // Only a measurement.
    } on MissingPluginException {
      // Not in the real app: a test.
    }
  }
}

@Riverpod(keepAlive: true)
Startup startup(Ref ref) => Startup();
