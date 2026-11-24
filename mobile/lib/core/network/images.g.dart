// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'images.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Replaced in tests, which have no network.

@ProviderFor(pictureLoader)
final pictureLoaderProvider = PictureLoaderProvider._();

/// Replaced in tests, which have no network.

final class PictureLoaderProvider
    extends $FunctionalProvider<PictureLoader, PictureLoader, PictureLoader>
    with $Provider<PictureLoader> {
  /// Replaced in tests, which have no network.
  PictureLoaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pictureLoaderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pictureLoaderHash();

  @$internal
  @override
  $ProviderElement<PictureLoader> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PictureLoader create(Ref ref) {
    return pictureLoader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PictureLoader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PictureLoader>(value),
    );
  }
}

String _$pictureLoaderHash() => r'aa46025439fdb1acc4dcbccfada89a932e393dd8';

@ProviderFor(pictureKeeper)
final pictureKeeperProvider = PictureKeeperProvider._();

final class PictureKeeperProvider
    extends $FunctionalProvider<PictureKeeper, PictureKeeper, PictureKeeper>
    with $Provider<PictureKeeper> {
  PictureKeeperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pictureKeeperProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pictureKeeperHash();

  @$internal
  @override
  $ProviderElement<PictureKeeper> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PictureKeeper create(Ref ref) {
    return pictureKeeper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PictureKeeper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PictureKeeper>(value),
    );
  }
}

String _$pictureKeeperHash() => r'e6073654a4921a53fc45a98348a2edae5a5e037f';

/// Where one picture lives at the width it is shown: the CDN's nearest variant, one size down to save data.

@ProviderFor(Pictures)
final picturesProvider = PicturesProvider._();

/// Where one picture lives at the width it is shown: the CDN's nearest variant, one size down to save data.
final class PicturesProvider
    extends $NotifierProvider<Pictures, ({String base, bool saver})> {
  /// Where one picture lives at the width it is shown: the CDN's nearest variant, one size down to save data.
  PicturesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'picturesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$picturesHash();

  @$internal
  @override
  Pictures create() => Pictures();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({String base, bool saver}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({String base, bool saver})>(value),
    );
  }
}

String _$picturesHash() => r'bb320a942289309bca5c9077e2a88fabfe089681';

/// Where one picture lives at the width it is shown: the CDN's nearest variant, one size down to save data.

abstract class _$Pictures extends $Notifier<({String base, bool saver})> {
  ({String base, bool saver}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<({String base, bool saver}), ({String base, bool saver})>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({String base, bool saver}),
                ({String base, bool saver})
              >,
              ({String base, bool saver}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
