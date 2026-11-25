// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_tabs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeTabs)
final homeTabsProvider = HomeTabsProvider._();

final class HomeTabsProvider
    extends $FunctionalProvider<List<HomeTab>, List<HomeTab>, List<HomeTab>>
    with $Provider<List<HomeTab>> {
  HomeTabsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeTabsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeTabsHash();

  @$internal
  @override
  $ProviderElement<List<HomeTab>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<HomeTab> create(Ref ref) {
    return homeTabs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HomeTab> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HomeTab>>(value),
    );
  }
}

String _$homeTabsHash() => r'c04bd780e5e71e46f65275205ed0f14e9c1626de';
