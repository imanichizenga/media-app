// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeds.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeFeed)
final homeFeedProvider = HomeFeedProvider._();

final class HomeFeedProvider extends $AsyncNotifierProvider<HomeFeed, Loaded<Home>> {
  HomeFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeFeedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeFeedHash();

  @$internal
  @override
  HomeFeed create() => HomeFeed();
}

String _$homeFeedHash() => r'a87ff2ae21cdd3aa4711b8923580c8ffa67d0fb5';

abstract class _$HomeFeed extends $AsyncNotifier<Loaded<Home>> {
  FutureOr<Loaded<Home>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Loaded<Home>>, Loaded<Home>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Loaded<Home>>, Loaded<Home>>,
              AsyncValue<Loaded<Home>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(Navigation)
final navigationProvider = NavigationProvider._();

final class NavigationProvider
    extends $AsyncNotifierProvider<Navigation, Loaded<List<NavigationItem>>> {
  NavigationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navigationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navigationHash();

  @$internal
  @override
  Navigation create() => Navigation();
}

String _$navigationHash() => r'e5c98384793e28d6634ed84353bdf896f5b62fa8';

abstract class _$Navigation extends $AsyncNotifier<Loaded<List<NavigationItem>>> {
  FutureOr<Loaded<List<NavigationItem>>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<Loaded<List<NavigationItem>>>, Loaded<List<NavigationItem>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Loaded<List<NavigationItem>>>, Loaded<List<NavigationItem>>>,
              AsyncValue<Loaded<List<NavigationItem>>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(Feed)
final feedProvider = FeedFamily._();

final class FeedProvider extends $AsyncNotifierProvider<Feed, FeedState> {
  FeedProvider._({required FeedFamily super.from, required FeedKey super.argument})
    : super(
        retry: null,
        name: r'feedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedHash();

  @override
  String toString() {
    return r'feedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Feed create() => Feed();

  @override
  bool operator ==(Object other) {
    return other is FeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedHash() => r'45b9ed29c7d8e7fdb9be88caf4fd9610c1e58d19';

final class FeedFamily extends $Family
    with
        $ClassFamilyOverride<Feed, AsyncValue<FeedState>, FeedState, FutureOr<FeedState>, FeedKey> {
  FeedFamily._()
    : super(
        retry: null,
        name: r'feedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedProvider call(FeedKey key) => FeedProvider._(argument: key, from: this);

  @override
  String toString() => r'feedProvider';
}

abstract class _$Feed extends $AsyncNotifier<FeedState> {
  late final _$args = ref.$arg as FeedKey;
  FeedKey get key => _$args;

  FutureOr<FeedState> build(FeedKey key);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FeedState>, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedState>, FeedState>,
              AsyncValue<FeedState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Which article: its slug is unique within a language.

@ProviderFor(ArticleOf)
final articleOfProvider = ArticleOfFamily._();

/// Which article: its slug is unique within a language.
final class ArticleOfProvider extends $AsyncNotifierProvider<ArticleOf, Loaded<Article>> {
  /// Which article: its slug is unique within a language.
  ArticleOfProvider._({
    required ArticleOfFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'articleOfProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articleOfHash();

  @override
  String toString() {
    return r'articleOfProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ArticleOf create() => ArticleOf();

  @override
  bool operator ==(Object other) {
    return other is ArticleOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleOfHash() => r'3279c2fec2e2ee28dbfeefa9574d961496f91d50';

/// Which article: its slug is unique within a language.

final class ArticleOfFamily extends $Family
    with
        $ClassFamilyOverride<
          ArticleOf,
          AsyncValue<Loaded<Article>>,
          Loaded<Article>,
          FutureOr<Loaded<Article>>,
          (String, String)
        > {
  ArticleOfFamily._()
    : super(
        retry: null,
        name: r'articleOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Which article: its slug is unique within a language.

  ArticleOfProvider call(String slug, String locale) =>
      ArticleOfProvider._(argument: (slug, locale), from: this);

  @override
  String toString() => r'articleOfProvider';
}

/// Which article: its slug is unique within a language.

abstract class _$ArticleOf extends $AsyncNotifier<Loaded<Article>> {
  late final _$args = ref.$arg as (String, String);
  String get slug => _$args.$1;
  String get locale => _$args.$2;

  FutureOr<Loaded<Article>> build(String slug, String locale);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Loaded<Article>>, Loaded<Article>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Loaded<Article>>, Loaded<Article>>,
              AsyncValue<Loaded<Article>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(related)
final relatedProvider = RelatedFamily._();

final class RelatedProvider
    extends $FunctionalProvider<AsyncValue<List<Story>>, List<Story>, FutureOr<List<Story>>>
    with $FutureModifier<List<Story>>, $FutureProvider<List<Story>> {
  RelatedProvider._({required RelatedFamily super.from, required (String, String) super.argument})
    : super(
        retry: null,
        name: r'relatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$relatedHash();

  @override
  String toString() {
    return r'relatedProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Story>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Story>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return related(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$relatedHash() => r'd72df5dd01925f760bab37bd03f1b5f7ff072793';

final class RelatedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Story>>, (String, String)> {
  RelatedFamily._()
    : super(
        retry: null,
        name: r'relatedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RelatedProvider call(String slug, String locale) =>
      RelatedProvider._(argument: (slug, locale), from: this);

  @override
  String toString() => r'relatedProvider';
}

/// Where an old address lives now, or null.

@ProviderFor(moved)
final movedProvider = MovedFamily._();

/// Where an old address lives now, or null.

final class MovedProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Where an old address lives now, or null.
  MovedProvider._({required MovedFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'movedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$movedHash();

  @override
  String toString() {
    return r'movedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return moved(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MovedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$movedHash() => r'ae875ad125c1115bfa0e974416611ac527544e2e';

/// Where an old address lives now, or null.

final class MovedFamily extends $Family with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  MovedFamily._()
    : super(
        retry: null,
        name: r'movedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Where an old address lives now, or null.

  MovedProvider call(String path) => MovedProvider._(argument: path, from: this);

  @override
  String toString() => r'movedProvider';
}
