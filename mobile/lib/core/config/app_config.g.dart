// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the server says about this version of the app. The last answer is on the phone, so a start without a
/// connection still knows the brand, the flags and whether this version is allowed.

@ProviderFor(AppConfigController)
final appConfigControllerProvider = AppConfigControllerProvider._();

/// What the server says about this version of the app. The last answer is on the phone, so a start without a
/// connection still knows the brand, the flags and whether this version is allowed.
final class AppConfigControllerProvider
    extends $AsyncNotifierProvider<AppConfigController, AppConfig?> {
  /// What the server says about this version of the app. The last answer is on the phone, so a start without a
  /// connection still knows the brand, the flags and whether this version is allowed.
  AppConfigControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appConfigControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appConfigControllerHash();

  @$internal
  @override
  AppConfigController create() => AppConfigController();
}

String _$appConfigControllerHash() => r'22148b5d4ff67b3ed1ccc3114627ca973b1d763b';

/// What the server says about this version of the app. The last answer is on the phone, so a start without a
/// connection still knows the brand, the flags and whether this version is allowed.

abstract class _$AppConfigController extends $AsyncNotifier<AppConfig?> {
  FutureOr<AppConfig?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppConfig?>, AppConfig?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppConfig?>, AppConfig?>,
              AsyncValue<AppConfig?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(appStatus)
final appStatusProvider = AppStatusProvider._();

final class AppStatusProvider extends $FunctionalProvider<AppStatus, AppStatus, AppStatus>
    with $Provider<AppStatus> {
  AppStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appStatusHash();

  @$internal
  @override
  $ProviderElement<AppStatus> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppStatus create(Ref ref) {
    return appStatus(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppStatus value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppStatus>(value));
  }
}

String _$appStatusHash() => r'990ab50f3dbaa97e38b93d6ce404bc626e73a563';

@ProviderFor(mediaBase)
final mediaBaseProvider = MediaBaseProvider._();

final class MediaBaseProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  MediaBaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaBaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaBaseHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return mediaBase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String>(value));
  }
}

String _$mediaBaseHash() => r'f1585690f7c37efc6adffadcae299ce3f272cb0f';

@ProviderFor(apiBase)
final apiBaseProvider = ApiBaseProvider._();

final class ApiBaseProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  ApiBaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiBaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiBaseHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return apiBase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String>(value));
  }
}

String _$apiBaseHash() => r'8ec76753604cdefaa33cd3f556bcb08eb1814e52';

@ProviderFor(brand)
final brandProvider = BrandProvider._();

final class BrandProvider extends $FunctionalProvider<Brand, Brand, Brand> with $Provider<Brand> {
  BrandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandHash();

  @$internal
  @override
  $ProviderElement<Brand> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Brand create(Ref ref) {
    return brand(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Brand value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Brand>(value));
  }
}

String _$brandHash() => r'8f408796885be13bda689fdf2c7e9e07022aad1e';

@ProviderFor(flags)
final flagsProvider = FlagsProvider._();

final class FlagsProvider extends $FunctionalProvider<AppFlags, AppFlags, AppFlags>
    with $Provider<AppFlags> {
  FlagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flagsHash();

  @$internal
  @override
  $ProviderElement<AppFlags> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppFlags create(Ref ref) {
    return flags(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppFlags value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppFlags>(value));
  }
}

String _$flagsHash() => r'688c8ff494a407b761d079f84e410149bd45c55e';
