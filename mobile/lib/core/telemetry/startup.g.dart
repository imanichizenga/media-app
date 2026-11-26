// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(startup)
final startupProvider = StartupProvider._();

final class StartupProvider extends $FunctionalProvider<Startup, Startup, Startup>
    with $Provider<Startup> {
  StartupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupHash();

  @$internal
  @override
  $ProviderElement<Startup> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Startup create(Ref ref) {
    return startup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Startup value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Startup>(value));
  }
}

String _$startupHash() => r'99e1c0b7540df2788677781009cd9566204444c9';
