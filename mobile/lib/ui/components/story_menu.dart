import 'package:flutter/widgets.dart';

import '../../core/models.dart';

/// What happens when a card is held. The app fills it in; a card outside it cannot be held.
class StoryMenu extends InheritedWidget {
  const StoryMenu({super.key, required this.open, required super.child});

  final void Function(BuildContext context, Story story, Widget preview) open;

  static StoryMenu? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoryMenu>();

  @override
  bool updateShouldNotify(StoryMenu old) => false;
}
