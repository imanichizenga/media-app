// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Opened by the bootstrap, before the first frame.

@ProviderFor(database)
final databaseProvider = DatabaseProvider._();

/// Opened by the bootstrap, before the first frame.

final class DatabaseProvider extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Opened by the bootstrap, before the first frame.
  DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'772a62c92559877a10ff5cf035fbfdd25bcc317a';

@ProviderFor(initialSettings)
final initialSettingsProvider = InitialSettingsProvider._();

final class InitialSettingsProvider extends $FunctionalProvider<Settings, Settings, Settings>
    with $Provider<Settings> {
  InitialSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialSettingsHash();

  @$internal
  @override
  $ProviderElement<Settings> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Settings create(Ref ref) {
    return initialSettings(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Settings value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Settings>(value));
  }
}

String _$initialSettingsHash() => r'd7ee96d3a992e0916aac1373e9c9702d0f8fc85a';

/// Applied for the whole session: a theme published meanwhile waits for the next cold start.

@ProviderFor(themeChoice)
final themeChoiceProvider = ThemeChoiceProvider._();

/// Applied for the whole session: a theme published meanwhile waits for the next cold start.

final class ThemeChoiceProvider extends $FunctionalProvider<ThemeChoice, ThemeChoice, ThemeChoice>
    with $Provider<ThemeChoice> {
  /// Applied for the whole session: a theme published meanwhile waits for the next cold start.
  ThemeChoiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeChoiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeChoiceHash();

  @$internal
  @override
  $ProviderElement<ThemeChoice> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ThemeChoice create(Ref ref) {
    return themeChoice(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeChoice value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeChoice>(value),
    );
  }
}

String _$themeChoiceHash() => r'a71f9ca459c228dd73ea5404b018dfd160bfe56a';

@ProviderFor(packageInfo)
final packageInfoProvider = PackageInfoProvider._();

final class PackageInfoProvider extends $FunctionalProvider<PackageInfo, PackageInfo, PackageInfo>
    with $Provider<PackageInfo> {
  PackageInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packageInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packageInfoHash();

  @$internal
  @override
  $ProviderElement<PackageInfo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PackageInfo create(Ref ref) {
    return packageInfo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PackageInfo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PackageInfo>(value),
    );
  }
}

String _$packageInfoHash() => r'2fe8a1dad072c03ba27399ac01c4cc38f0337013';

@ProviderFor(analytics)
final analyticsProvider = AnalyticsProvider._();

final class AnalyticsProvider extends $FunctionalProvider<Analytics, Analytics, Analytics>
    with $Provider<Analytics> {
  AnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsHash();

  @$internal
  @override
  $ProviderElement<Analytics> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Analytics create(Ref ref) {
    return analytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Analytics value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Analytics>(value));
  }
}

String _$analyticsHash() => r'e7ebfc19abb5dd49b3397c75139b287fea88e123';

/// Replaced in tests, so every "five minutes ago" is fixed.

@ProviderFor(clockNow)
final clockNowProvider = ClockNowProvider._();

/// Replaced in tests, so every "five minutes ago" is fixed.

final class ClockNowProvider
    extends $FunctionalProvider<DateTime Function(), DateTime Function(), DateTime Function()>
    with $Provider<DateTime Function()> {
  /// Replaced in tests, so every "five minutes ago" is fixed.
  ClockNowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockNowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockNowHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return clockNow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$clockNowHash() => r'17a53e4b045603c6f1046a0432640a9fc1506c41';

@ProviderFor(SettingsController)
final settingsControllerProvider = SettingsControllerProvider._();

final class SettingsControllerProvider extends $NotifierProvider<SettingsController, Settings> {
  SettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsControllerHash();

  @$internal
  @override
  SettingsController create() => SettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Settings value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Settings>(value));
  }
}

String _$settingsControllerHash() => r'9f7c6c7c87a35903f062b0965e1d126588a1e087';

abstract class _$SettingsController extends $Notifier<Settings> {
  Settings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Settings, Settings>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<Settings, Settings>, Settings, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(localeName)
final localeNameProvider = LocaleNameProvider._();

final class LocaleNameProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  LocaleNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localeNameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localeNameHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return localeName(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String>(value));
  }
}

String _$localeNameHash() => r'7d752333304d03a9e9e48a84687376c3b7695983';

/// One random id per installation, in the keychain. Read after the first frame; requests before it go without.

@ProviderFor(DeviceId)
final deviceIdProvider = DeviceIdProvider._();

/// One random id per installation, in the keychain. Read after the first frame; requests before it go without.
final class DeviceIdProvider extends $NotifierProvider<DeviceId, String?> {
  /// One random id per installation, in the keychain. Read after the first frame; requests before it go without.
  DeviceIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdHash();

  @$internal
  @override
  DeviceId create() => DeviceId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String?>(value));
  }
}

String _$deviceIdHash() => r'df2e1e32947646efd6053b14e6b825d63c2ed8be';

/// One random id per installation, in the keychain. Read after the first frame; requests before it go without.

abstract class _$DeviceId extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<String?, String?>, String?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(pinning)
final pinningProvider = PinningProvider._();

final class PinningProvider extends $FunctionalProvider<Pinning, Pinning, Pinning>
    with $Provider<Pinning> {
  PinningProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pinningProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pinningHash();

  @$internal
  @override
  $ProviderElement<Pinning> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Pinning create(Ref ref) {
    return pinning(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Pinning value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Pinning>(value));
  }
}

String _$pinningHash() => r'47362011290f761338fb63e9d50fe4ad786a495b';

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio> with $Provider<Dio> {
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Dio>(value));
  }
}

String _$dioHash() => r'e1686f9769be52d2219765826d92a2af18b0b08f';

@ProviderFor(contentApi)
final contentApiProvider = ContentApiProvider._();

final class ContentApiProvider extends $FunctionalProvider<ContentApi, ContentApi, ContentApi>
    with $Provider<ContentApi> {
  ContentApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'contentApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$contentApiHash();

  @$internal
  @override
  $ProviderElement<ContentApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ContentApi create(Ref ref) {
    return contentApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ContentApi value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ContentApi>(value));
  }
}

String _$contentApiHash() => r'555482ecb0031a494647528ec4da1bb73c505724';

/// Without pins on purpose: this is the answer that can switch a wrong pin off.

@ProviderFor(appConfigApi)
final appConfigApiProvider = AppConfigApiProvider._();

/// Without pins on purpose: this is the answer that can switch a wrong pin off.

final class AppConfigApiProvider
    extends $FunctionalProvider<AppConfigApi, AppConfigApi, AppConfigApi>
    with $Provider<AppConfigApi> {
  /// Without pins on purpose: this is the answer that can switch a wrong pin off.
  AppConfigApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigApiHash();

  @$internal
  @override
  $ProviderElement<AppConfigApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppConfigApi create(Ref ref) {
    return appConfigApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppConfigApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppConfigApi>(value),
    );
  }
}

String _$appConfigApiHash() => r'5612227440675ef229ad8461bfcf74ccc675af4e';

/// Whether the phone believes it has a connection. The truth is in each request; this only says when to try again.

@ProviderFor(online)
final onlineProvider = OnlineProvider._();

/// Whether the phone believes it has a connection. The truth is in each request; this only says when to try again.

final class OnlineProvider extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Whether the phone believes it has a connection. The truth is in each request; this only says when to try again.
  OnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return online(ref);
  }
}

String _$onlineHash() => r'2778bd5118983521a5323c981d56ba047b4524ef';

/// On mobile data, with the saver on, videos wait for a tap.

@ProviderFor(autoplay)
final autoplayProvider = AutoplayProvider._();

/// On mobile data, with the saver on, videos wait for a tap.

final class AutoplayProvider extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// On mobile data, with the saver on, videos wait for a tap.
  AutoplayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoplayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoplayHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return autoplay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$autoplayHash() => r'2fc858f12c4de74848ba092a31f4ca1d57d1711f';
