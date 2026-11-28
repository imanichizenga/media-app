import 'package:material_ui/material_ui.dart';

import 'package:news_design_tokens/news_design_tokens.dart';

/// Paid reading (ADR-0052): the crown's gold and the plan cards' colours, the same as the website's
/// (web/app/globals.css). Gold whatever the brand; each plan's top in the colour the newsroom chose for it.
abstract final class Premium {
  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7D774), Color(0xFFE0A526), Color(0xFFB8741A)],
  );
  static const glow = [BoxShadow(color: Color(0x66E0A526), blurRadius: 18, offset: Offset(0, 6))];
  static const wash = Color(0x22F7D774);
  static const ink = Color(0xFFFFFFFF);
  static const inkSoft = Color(0xD9FFFFFF);
  static const clear = Color(0x00000000);
  static const card = [BoxShadow(color: Color(0x1F000000), blurRadius: 28, offset: Offset(0, 10))];
  static const chosen = [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
  static const raised = [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))];

  /// The mark on a card: dark gold on a pale wash, or light gold on a dark one.
  static Color markInk(bool dark) => dark ? const Color(0xFFF7D774) : const Color(0xFF8A5A0B);
  static Color markWash(bool dark) => dark ? const Color(0x38E0A526) : const Color(0x73F7D774);

  /// What fades the end of a story's opening into the page (a mask: only its alpha counts).
  static const fade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
    stops: [0, 0.6, 1],
  );

  static LinearGradient tone(String tone, NewsColors c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: switch (tone) {
      'ember' => const [Color(0xFF6D1A0C), Color(0xFFD9481A), Color(0xFFF59E3D)],
      'ocean' => const [Color(0xFF0A2463), Color(0xFF1D4FD8), Color(0xFF3AA0FF)],
      'forest' => const [Color(0xFF0B3A2C), Color(0xFF12795A), Color(0xFF3CBF88)],
      'violet' => const [Color(0xFF2A0D5C), Color(0xFF6A28D4), Color(0xFFC06BFF)],
      'night' => const [Color(0xFF070B14), Color(0xFF222C45), Color(0xFF4D5875)],
      _ => [c.brandStrong, c.brand, const Color(0xFFE4572E)],
    },
  );
}
