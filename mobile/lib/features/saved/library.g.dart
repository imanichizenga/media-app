// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savedStories)
final savedStoriesProvider = SavedStoriesProvider._();

final class SavedStoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedStory>>,
          List<SavedStory>,
          Stream<List<SavedStory>>
        >
    with $FutureModifier<List<SavedStory>>, $StreamProvider<List<SavedStory>> {
  SavedStoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedStoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedStoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<SavedStory>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<SavedStory>> create(Ref ref) {
    return savedStories(ref);
  }
}

String _$savedStoriesHash() => r'42da02ab45e1f1a2ec53521ad30730506a8c56b7';

@ProviderFor(historyStories)
final historyStoriesProvider = HistoryStoriesProvider._();

final class HistoryStoriesProvider
    extends
        $FunctionalProvider<AsyncValue<List<ReadStory>>, List<ReadStory>, Stream<List<ReadStory>>>
    with $FutureModifier<List<ReadStory>>, $StreamProvider<List<ReadStory>> {
  HistoryStoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyStoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyStoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<ReadStory>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ReadStory>> create(Ref ref) {
    return historyStories(ref);
  }
}

String _$historyStoriesHash() => r'5a403d3ed69795dd9fba57b30ddf3a4347634798';

@ProviderFor(isSaved)
final isSavedProvider = IsSavedFamily._();

final class IsSavedProvider extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  IsSavedProvider._({required IsSavedFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'isSavedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isSavedHash();

  @override
  String toString() {
    return r'isSavedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isSaved(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }

  @override
  bool operator ==(Object other) {
    return other is IsSavedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isSavedHash() => r'5d025238b56e0ef60f2bb95350aa4b1a14d283ce';

final class IsSavedFamily extends $Family with $FunctionalFamilyOverride<bool, String> {
  IsSavedFamily._()
    : super(
        retry: null,
        name: r'isSavedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsSavedProvider call(String path) => IsSavedProvider._(argument: path, from: this);

  @override
  String toString() => r'isSavedProvider';
}

/// The saved copy, for reading without a connection.

@ProviderFor(savedArticle)
final savedArticleProvider = SavedArticleFamily._();

/// The saved copy, for reading without a connection.

final class SavedArticleProvider
    extends $FunctionalProvider<AsyncValue<Article?>, Article?, FutureOr<Article?>>
    with $FutureModifier<Article?>, $FutureProvider<Article?> {
  /// The saved copy, for reading without a connection.
  SavedArticleProvider._({required SavedArticleFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'savedArticleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedArticleHash();

  @override
  String toString() {
    return r'savedArticleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Article?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Article?> create(Ref ref) {
    final argument = this.argument as String;
    return savedArticle(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedArticleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedArticleHash() => r'57df292acd737620b8f25777d00540cbf1fc97d8';

/// The saved copy, for reading without a connection.

final class SavedArticleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Article?>, String> {
  SavedArticleFamily._()
    : super(
        retry: null,
        name: r'savedArticleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The saved copy, for reading without a connection.

  SavedArticleProvider call(String path) => SavedArticleProvider._(argument: path, from: this);

  @override
  String toString() => r'savedArticleProvider';
}

@ProviderFor(Library)
final libraryProvider = LibraryProvider._();

final class LibraryProvider extends $NotifierProvider<Library, void> {
  LibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryHash();

  @$internal
  @override
  Library create() => Library();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$libraryHash() => r'25ecb977bc2d9e6b0cdee5cefa5c62b29fd180db';

abstract class _$Library extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
