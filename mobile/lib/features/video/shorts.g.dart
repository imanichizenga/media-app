// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shorts.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Replaced in tests.

@ProviderFor(makeController)
final makeControllerProvider = MakeControllerProvider._();

/// Replaced in tests.

final class MakeControllerProvider
    extends $FunctionalProvider<MakeController, MakeController, MakeController>
    with $Provider<MakeController> {
  /// Replaced in tests.
  MakeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'makeControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$makeControllerHash();

  @$internal
  @override
  $ProviderElement<MakeController> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MakeController create(Ref ref) {
    return makeController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MakeController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MakeController>(value),
    );
  }
}

String _$makeControllerHash() => r'ba4f23e75bba2316651ad728ffd67d52282ad4e4';
