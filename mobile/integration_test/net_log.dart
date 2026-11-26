// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

/// Every socket the app opens during the device tests, printed with how long it took and its local port, so the
/// recorded API's own log (support/tests/replay.mjs) can be matched to it line for line (ADR-0048). It only watches:
/// the client's timeouts and everything else are the app's own.
class NetLog extends HttpOverrides {
  NetLog() : _clock = Stopwatch()..start();

  final Stopwatch _clock;

  /// Seconds since the tests began, and the wall clock (the simulator shares the host's, so it matches the replay log).
  String get at =>
      '${(_clock.elapsedMilliseconds / 1000).toStringAsFixed(1)} ${DateTime.now().toUtc().toIso8601String().substring(11, 23)}';

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      final host = proxyHost ?? uri.host;
      final port = proxyPort ?? uri.port;
      final started = _clock.elapsedMilliseconds;
      print('NET $at s connect $host:$port');
      final task = uri.scheme == 'https'
          ? await SecureSocket.startConnect(host, port, context: context)
          : await Socket.startConnect(host, port);
      unawaited(
        task.socket.then(
          (s) => print('NET $at s connected $host:$port local ${s.port} in ${_clock.elapsedMilliseconds - started} ms'),
          onError: (Object e) =>
              print('NET $at s failed $host:$port in ${_clock.elapsedMilliseconds - started} ms: $e'),
        ),
      );
      return task;
    };
    return client;
  }
}
