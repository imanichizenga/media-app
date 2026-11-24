import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart' show MaterialPage;
import 'package:news_design_tokens/news_design_tokens.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/models.dart';
import '../core/providers.dart';
import '../features/article/article_screen.dart';
import '../features/content/feeds.dart';
import '../features/content/list_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/system/not_found_screen.dart';
import '../features/video/video_screen.dart';
import '../features/you/you_screen.dart';
import '../ui/tokens/theme.dart';
import 'links.dart';
import 'shell.dart';

part 'router.g.dart';

final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

@TypedStatefulShellRoute<ShellRoute>(
  branches: [
    TypedStatefulShellBranch<HomeBranch>(routes: [TypedGoRoute<HomeRoute>(path: '/')]),
    TypedStatefulShellBranch<VideoBranch>(routes: [TypedGoRoute<VideoRoute>(path: '/video')]),
    TypedStatefulShellBranch<ExploreBranch>(routes: [TypedGoRoute<ExploreRoute>(path: '/search')]),
    TypedStatefulShellBranch<SavedBranch>(routes: [TypedGoRoute<SavedRoute>(path: '/saved')]),
    TypedStatefulShellBranch<YouBranch>(routes: [TypedGoRoute<YouRoute>(path: '/profile')]),
  ],
)
class ShellRoute extends StatefulShellRouteData {
  const ShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, StatefulNavigationShell shell) =>
      AppShell(shell: shell);
}

class HomeBranch extends StatefulShellBranchData {
  const HomeBranch();
}

class VideoBranch extends StatefulShellBranchData {
  const VideoBranch();
}

class ExploreBranch extends StatefulShellBranchData {
  const ExploreBranch();
}

class SavedBranch extends StatefulShellBranchData {
  const SavedBranch();
}

class YouBranch extends StatefulShellBranchData {
  const YouBranch();
}

class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class VideoRoute extends GoRouteData with $VideoRoute {
  const VideoRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const VideoScreen();
}

class ExploreRoute extends GoRouteData with $ExploreRoute {
  const ExploreRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const ExploreScreen();
}

class SavedRoute extends GoRouteData with $SavedRoute {
  const SavedRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const SavedScreen();
}

class YouRoute extends GoRouteData with $YouRoute {
  const YouRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const YouScreen();
}

@TypedGoRoute<OnboardingRoute>(path: '/welcome')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const OnboardingScreen();
}

/// Everything else is an address of the website. What it means is decided in one place, `parsePlace`.
Page<void> _content(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  name: state.uri.path,
  transitionDuration: NewsMotion.slow,
  reverseTransitionDuration: NewsMotion.base,
  child: child,
  transitionsBuilder: (context, animation, _, child) {
    if (context.still) return child;
    final eased = CurvedAnimation(parent: animation, curve: NewsMotion.standard);
    return FadeTransition(
      opacity: eased,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(eased),
        child: child,
      ),
    );
  },
);

Widget screenFor(String path, {StoryExtra? extra}) => switch (parsePlace(path)) {
  ArticlePlace(:final locale, :final slug) => ArticleScreen(
    slug: slug,
    locale: locale,
    path: path,
    extra: extra,
  ),
  ListPlace(:final kind, :final locale, :final slug) => ListScreen(
    feed: FeedKey(FeedKind.values.byName(kind), slug, locale),
    path: path,
  ),
  TabPlace() || OutsidePlace() => NotFoundScreen(path: path),
};

/// The app's own pages and the website's, in one router.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final content = [
    for (final path in const [
      '/:a',
      '/:a/:b',
      '/:a/:b/:c',
    ])
      GoRoute(
        path: path,
        parentNavigatorKey: rootKey,
        redirect: (context, state) => switch (parsePlace(state.uri.path)) {
          TabPlace(path: final tab) when tab != state.uri.path => tab,
          _ => null,
        },
        pageBuilder: (context, state) => _content(
          state,
          screenFor(state.uri.path, extra: state.extra as StoryExtra?),
        ),
      ),
  ];
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    routes: [...$appRoutes, ...content],
    redirect: (context, state) {
      // Once, and only where the reader would otherwise have landed on Home: a link is never interrupted.
      final done = ref.read(settingsControllerProvider).onboarded;
      if (!done && state.uri.path == '/') return '/welcome';
      if (done && state.uri.path == '/welcome') return '/';
      return null;
    },
    errorPageBuilder: (context, state) =>
        MaterialPage(child: NotFoundScreen(path: state.uri.path)),
  );
  ref.onDispose(router.dispose);
  return router;
}

/// Opens a story over whatever is shown, with what its card already knows.
void openStory(BuildContext context, Story story, {String? heroTag, String from = ''}) =>
    context.push(story.path, extra: StoryExtra(story, heroTag: heroTag, from: from));
