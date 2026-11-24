import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../app/router.dart';
import '../../app/shell.dart';
import '../../core/models.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/components/cards.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/states/designed.dart';
import '../../ui/tokens/news_icon.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../../ui/tokens/theme.dart';
import '../explore/explore_screen.dart' show BigTitle;
import 'library.dart';

/// What the reader kept, and what they read. On this phone.
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final _scroll = ScrollController();
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    tabAgain[3].addListener(_top);
  }

  @override
  void dispose() {
    tabAgain[3].removeListener(_top);
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    if (_scroll.hasClients) {
      unawaited(_scroll.animateTo(0, duration: NewsMotion.slow * 2, curve: NewsMotion.standard));
    }
  }

  Future<void> _clear() async {
    final s = Strings.of(context);
    final c = context.colors;
    final yes = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.clearHistory, style: context.type.headlineS.copyWith(color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(
                s.clearHistoryConfirm,
                style: context.type.bodyM.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 24),
              NewsButton(s.clear, wide: true, onTap: () => Navigator.pop(context, true)),
              const SizedBox(height: 8),
              NewsButton(
                s.cancel,
                wide: true,
                kind: ButtonKind.quiet,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes ?? false) await ref.read(libraryProvider.notifier).clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final c = context.colors;
    final history = ref.watch(historyStoriesProvider).value;
    void open(Story story, {String? heroTag}) =>
        openStory(context, story, heroTag: heroTag, from: 'saved');
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayFor(c.bg),
      child: Scaffold(
        body: Shimmer(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: BigTitle(
                  s.navSaved,
                  trailing: _tab == 1 && (history?.isNotEmpty ?? false)
                      ? RoundButton(NewsIcons.trash2, label: s.clearHistory, onTap: _clear)
                      : null,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Segmented(
                        labels: [s.savedTab, s.historyTab],
                        at: _tab,
                        onChanged: (i) => setState(() => _tab = i),
                      ),
                    ),
                  ),
                ),
              ),
              if (_tab == 0) ..._saved(open) else ..._history(history, open),
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bones(OpenStory open) => [
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(itemCount: 6, itemBuilder: (_, _) => RowCard(null, open: open)),
    ),
  ];

  List<Widget> _saved(OpenStory open) {
    final s = Strings.of(context);
    final c = context.colors;
    final saved = ref.watch(savedStoriesProvider).value;
    if (saved == null) return _bones(open);
    if (saved.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Designed(
            drawing: Drawing.empty,
            title: s.savedEmptyTitle,
            body: s.savedEmptyBody,
            action: s.savedEmptyAction,
            onAction: () => const HomeRoute().go(context),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: saved.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final x = saved[i];
            return Dismissible(
              key: ValueKey(x.story.path),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: c.surfaceSunken,
                child: NewsIcon(NewsIcons.trash2, color: c.textPrimary),
              ),
              onDismissed: (_) => _remove(x),
              child: Semantics(
                customSemanticsActions: {
                  CustomSemanticsAction(label: s.unsave): () => _remove(x),
                },
                child: RowCard(
                  x.story,
                  open: open,
                  place: 'saved',
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        NewsIcon(
                          x.ready ? NewsIcons.circleCheck : NewsIcons.download,
                          size: 14,
                          color: x.ready ? c.success : c.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            x.ready ? s.availableOffline : s.downloading,
                            style: context.type.caption.copyWith(color: c.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  void _remove(SavedStory x) {
    final s = Strings.of(context);
    final library = ref.read(libraryProvider.notifier);
    unawaited(library.unsave(x.story));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(s.removed),
          action: SnackBarAction(label: s.undo, onPressed: () => library.save(x.story)),
        ),
      );
  }

  List<Widget> _history(List<ReadStory>? history, OpenStory open) {
    final s = Strings.of(context);
    final c = context.colors;
    if (history == null) return _bones(open);
    if (history.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Designed(
            drawing: Drawing.empty,
            title: s.historyEmptyTitle,
            body: s.historyEmptyBody,
            action: s.savedEmptyAction,
            onAction: () => const HomeRoute().go(context),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: history.length,
          separatorBuilder: (_, _) => const Divider(),
          itemBuilder: (context, i) {
            final x = history[i];
            return RowCard(
              x.story,
              open: open,
              place: 'history',
              trailing: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Semantics(
                  label: s.readingProgress(x.percent),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 96,
                      height: 4,
                      child: Stack(
                        children: [
                          ColoredBox(color: c.border, child: const SizedBox.expand()),
                          FractionallySizedBox(
                            widthFactor: x.percent / 100,
                            child: ColoredBox(
                              color: c.textPrimary,
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }
}
