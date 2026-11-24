import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/providers.dart';
import '../../l10n/gen/strings.dart';
import '../../ui/tokens/theme.dart';

Future<void> showTextSize(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (context) => const SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(NewsSpace.s6, 0, NewsSpace.s6, NewsSpace.s6),
      child: TextSizeControl(),
    ),
  ),
);

/// A sample that changes while one drags.
class TextSizeControl extends ConsumerWidget {
  const TextSizeControl({super.key, this.title = true});

  final bool title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final c = context.colors;
    final scale = ref.watch(settingsControllerProvider.select((x) => x.textScale));
    final type = context.type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title)
          Semantics(
            header: true,
            child: Text(s.textSize, style: type.headlineS.copyWith(color: c.textPrimary)),
          ),
        const SizedBox(height: NewsSpace.s3),
        Text(
          s.textSizeSample,
          style: type.bodyL.copyWith(color: c.textPrimary, fontSize: 18 * scale),
        ),
        const SizedBox(height: NewsSpace.s3),
        Row(
          children: [
            ExcludeSemantics(
              child: Text(
                'A',
                style: type.headlineS.copyWith(color: c.textSecondary, fontSize: 15),
              ),
            ),
            Expanded(
              child: Slider(
                value: scale,
                min: 0.85,
                max: 1.6,
                divisions: 5,
                label: '${(scale * 100).round()}%',
                semanticFormatterCallback: (v) => '${s.textSize}: ${(v * 100).round()}%',
                onChanged: (v) => ref
                    .read(settingsControllerProvider.notifier)
                    .change((x) => x.copyWith(textScale: v)),
              ),
            ),
            ExcludeSemantics(
              child: Text('A', style: type.headlineS.copyWith(color: c.textPrimary, fontSize: 28)),
            ),
          ],
        ),
      ],
    );
  }
}
