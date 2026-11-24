import 'package:flutter/foundation.dart';

/// The website's addresses are the app's: one link opens the same story in both (ADR-0024).
sealed class Place {
  const Place();
}

@immutable
class ArticlePlace extends Place {
  const ArticlePlace(this.locale, this.category, this.slug);
  final String locale;
  final String category;
  final String slug;

  @override
  bool operator ==(Object other) =>
      other is ArticlePlace &&
      other.locale == locale &&
      other.category == category &&
      other.slug == slug;
  @override
  int get hashCode => Object.hash(locale, category, slug);
  @override
  String toString() => 'article $locale/$category/$slug';
}

/// A list: a category, a tag, a story cluster or an author.
@immutable
class ListPlace extends Place {
  const ListPlace(this.kind, this.locale, this.slug);
  final String kind;
  final String locale;
  final String slug;

  @override
  bool operator ==(Object other) =>
      other is ListPlace && other.kind == kind && other.locale == locale && other.slug == slug;
  @override
  int get hashCode => Object.hash(kind, locale, slug);
  @override
  String toString() => '$kind $locale/$slug';
}

@immutable
class TabPlace extends Place {
  const TabPlace(this.path);
  final String path;

  @override
  bool operator ==(Object other) => other is TabPlace && other.path == path;
  @override
  int get hashCode => path.hashCode;
  @override
  String toString() => 'tab $path';
}

/// A page of the website the app does not draw: it opens in the browser.
class OutsidePlace extends Place {
  const OutsidePlace();
}

const tabPaths = ['/', '/video', '/search', '/saved', '/profile'];
const _lists = {'tag', 'story', 'author'};
const _outside = {
  'about',
  'contact',
  'privacy',
  'terms',
  'editorial-policy',
  'corrections',
  'rss',
  'feed',
  'api',
  'theme',
  'media', 'settings', 'sitemap', 'sitemaps', 'ads', 'app-ads', 'static', '_next', 'healthz', //
};

Place parsePlace(String path) {
  var parts = Uri.tryParse(path)?.pathSegments.where((p) => p.isNotEmpty).toList() ?? const [];
  var locale = 'sw';
  if (parts.isNotEmpty && parts.first == 'en') {
    locale = 'en';
    parts = parts.sublist(1);
  }
  if (parts.isEmpty) return const TabPlace('/');
  final first = parts.first;
  if (parts.length == 1) {
    if (tabPaths.contains('/$first')) return TabPlace('/$first');
    if (first == 'shorts' || first == 'live') return const TabPlace('/video');
    if (first == 'latest') return const TabPlace('/');
  }
  if (_outside.contains(first)) return const OutsidePlace();
  if (_lists.contains(first)) {
    return parts.length == 2 ? ListPlace(first, locale, parts[1]) : const OutsidePlace();
  }
  return switch (parts.length) {
    1 => ListPlace('category', locale, first),
    2 => ArticlePlace(locale, first, parts[1]),
    _ => const OutsidePlace(),
  };
}
