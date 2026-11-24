// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which half is shown, and which short to start from when one was tapped elsewhere.

@ProviderFor(VideoTab)
final videoTabProvider = VideoTabProvider._();

/// Which half is shown, and which short to start from when one was tapped elsewhere.
final class VideoTabProvider extends $NotifierProvider<VideoTab, int> {
  /// Which half is shown, and which short to start from when one was tapped elsewhere.
  VideoTabProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoTabProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoTabHash();

  @$internal
  @override
  VideoTab create() => VideoTab();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<int>(value));
  }
}

String _$videoTabHash() => r'f80556a767921555dcbbb59433ea48392413c320';

/// Which half is shown, and which short to start from when one was tapped elsewhere.

abstract class _$VideoTab extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(StartShort)
final startShortProvider = StartShortProvider._();

final class StartShortProvider extends $NotifierProvider<StartShort, String?> {
  StartShortProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startShortProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startShortHash();

  @$internal
  @override
  StartShort create() => StartShort();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String?>(value));
  }
}

String _$startShortHash() => r'e1c39ca64fbcd9354a540844d29c5a5fd8153194';

abstract class _$StartShort extends $Notifier<String?> {
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
