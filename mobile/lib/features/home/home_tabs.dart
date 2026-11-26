import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers.dart';
import '../content/feeds.dart';

part 'home_tabs.g.dart';

/// A page of Home: the two feeds, then the sections.
@immutable
class HomeTab {
  const HomeTab.forYou() : id = 'you', name = null, feed = null;
  const HomeTab.latest(this.feed) : id = 'latest', name = null;
  const HomeTab.section(this.id, String this.name, this.feed);

  final String id;

  /// Null: named by the app.
  final String? name;

  /// Null: the front page.
  final FeedKey? feed;

  @override
  bool operator ==(Object other) =>
      other is HomeTab && other.id == id && other.name == name && other.feed == feed;
  @override
  int get hashCode => Object.hash(id, name, feed);
}

@riverpod
List<HomeTab> homeTabs(Ref ref) {
  final locale = ref.watch(localeNameProvider);
  final sections = ref.watch(navigationProvider).value?.value ?? const [];
  return [
    const HomeTab.forYou(),
    HomeTab.latest(FeedKey(FeedKind.latest, '', locale)),
    for (final n in sections)
      HomeTab.section(n.id, n.name, FeedKey(FeedKind.category, n.slug, locale)),
  ];
}
