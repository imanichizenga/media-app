import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_config.dart';
import '../../core/config/env.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/telemetry/analytics.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/adaptive/adaptive.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../saved/library.dart';

Uri addressOf(Story story) => Uri.https(Env.webHost, story.path);

Future<void> shareStory(WidgetRef ref, Story story) async {
  ref.read(analyticsProvider).track(StoryShared(story.id));
  await SharePlus.instance.share(ShareParams(uri: addressOf(story), subject: story.headline));
}

/// Words from the story, with where they are from.
Future<void> shareQuote(WidgetRef ref, Story story, String words) async {
  ref.read(analyticsProvider).track(StoryShared(story.id));
  await SharePlus.instance.share(
    ShareParams(text: '“${words.trim()}”\n\n${story.headline}\n${addressOf(story)}'),
  );
}

/// What a held card offers (N5).
Future<void> openStoryMenu(BuildContext context, WidgetRef ref, Story story, Widget preview) async {
  final s = Strings.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final library = ref.read(libraryProvider.notifier);
  final saved = ref.read(isSavedProvider(story.path));
  void say(String words) => messenger
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(words)));
  await showActions(
    context,
    preview: preview,
    actions: [
      if (ref.read(flagsProvider).offlineSaving)
        (
          NewsIcons.bookmark,
          saved ? s.unsave : s.save,
          () {
            unawaited(saved ? library.unsave(story) : library.save(story));
            say(saved ? s.removed : s.savedDone);
          },
        ),
      (NewsIcons.share2, s.share, () => unawaited(shareStory(ref, story))),
      (
        NewsIcons.link2,
        s.copyLink,
        () {
          unawaited(Clipboard.setData(ClipboardData(text: addressOf(story).toString())));
          say(s.linkCopied);
        },
      ),
    ],
  );
}
