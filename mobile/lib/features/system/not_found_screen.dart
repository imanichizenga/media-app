import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/router.dart';
import '../../ui/components/skeleton.dart';
import '../../ui/states/designed.dart';
import '../../core/network/failures.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/components/basics.dart';
import '../../ui/tokens/news_icons.g.dart';
import '../content/feeds.dart';

/// An address nothing answers to. It may have moved: the server knows.
class NotFoundScreen extends ConsumerWidget {
  const NotFoundScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final to = ref.watch(movedProvider(path));
    ref.listen(movedProvider(path), (_, next) {
      if (next.value case final target?) context.replace(target);
    });
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: RoundButton(
                NewsIcons.arrowLeft,
                label: Strings.of(context).back,
                onTap: () => context.canPop() ? context.pop() : const HomeRoute().go(context),
              ),
            ),
            Expanded(
              child: to.isLoading || to.value != null
                  ? const Shimmer(child: Padding(padding: EdgeInsets.all(20), child: Bone.fill()))
                  : Center(
                      child: SingleChildScrollView(
                        child: Designed.failure(
                          context,
                          const NotFoundFailure(),
                          retry: () => ref.invalidate(movedProvider(path)),
                          home: () => const HomeRoute().go(context),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
