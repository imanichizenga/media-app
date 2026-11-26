import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../tokens/theme.dart';

/// What each place does when its tab is tapped again: the screen on top of it goes to its own top.
class Tops {
  final _of = List.generate(5, (_) => <bool Function()>[]);

  /// Whether there was anywhere to go.
  bool go(int place) => _of[place].isNotEmpty && _of[place].last();
}

class TopsScope extends InheritedWidget {
  const TopsScope({super.key, required this.tops, required this.at, required super.child});

  final Tops tops;
  final int at;

  @override
  bool updateShouldNotify(TopsScope old) => false;
}

/// A screen of a place. Outside the places (a link opened over them) it does nothing.
mixin GoesToTop<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final scroll = ScrollController();
  List<bool Function()>? _list;

  /// The list one sees.
  ScrollController get shown => scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_list != null) return;
    final scope = context.getInheritedWidgetOfExactType<TopsScope>();
    if (scope != null) _list = scope.tops._of[scope.at]..add(toTop);
  }

  @override
  void dispose() {
    _list?.remove(toTop);
    scroll.dispose();
    super.dispose();
  }

  bool toTop() {
    final c = shown;
    if (!c.hasClients || c.offset <= 8) return false;
    unawaited(
      c.animateTo(
        0,
        duration: context.still ? const Duration(milliseconds: 1) : NewsMotion.slow * 2,
        curve: NewsMotion.standard,
      ),
    );
    return true;
  }
}
