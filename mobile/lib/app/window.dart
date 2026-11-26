import 'package:flutter/widgets.dart';

/// ADR-0035.
enum WindowClass { compact, medium, expanded }

WindowClass windowOf(BuildContext context) => switch (MediaQuery.sizeOf(context).width) {
  < 600 => WindowClass.compact,
  < 840 => WindowClass.medium,
  _ => WindowClass.expanded,
};

/// Reading columns stop growing here.
const articleWidth = 680.0;
