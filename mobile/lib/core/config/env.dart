/// Build-time values (--dart-define-from-file=`config/FLAVOR.json`). Nothing here is secret.
abstract final class Env {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8010',
  );

  /// The website's host: links shared from the app point here, and links to it open in the app.
  static const webHost = String.fromEnvironment('WEB_HOST', defaultValue: 'dev.example.com');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
