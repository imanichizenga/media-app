import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:news_design_tokens/news_design_tokens.dart';

import '../../core/config/theme_choice.dart';

/// The type scale of the tokens, with the variable axis set. Serif speaks, sans works.
@immutable
class AppType extends ThemeExtension<AppType> {
  const AppType();

  static TextStyle _v(TextStyle s, {double spacing = 0}) => s.copyWith(
    fontVariations: [FontVariation('wght', s.fontWeight!.value.toDouble())],
    letterSpacing: spacing,
    leadingDistribution: TextLeadingDistribution.even,
  );

  TextStyle get display => _v(NewsType.display, spacing: -0.8);
  TextStyle get headlineL => _v(NewsType.headlineL, spacing: -0.5);
  TextStyle get headlineM => _v(NewsType.headlineM, spacing: -0.3);
  TextStyle get headlineS => _v(NewsType.headlineS, spacing: -0.1);
  TextStyle get title => _v(NewsType.title);
  TextStyle get bodyL => _v(NewsType.bodyL).copyWith(height: 1.65);
  TextStyle get bodyM => _v(NewsType.bodyM);
  TextStyle get label => _v(NewsType.label);
  TextStyle get caption => _v(NewsType.caption);

  /// The serif at body size: standfirsts and quotes.
  TextStyle get serif =>
      _v(NewsType.headlineS.copyWith(fontWeight: FontWeight.w400)).copyWith(height: 1.45);

  /// Small capitals' stand-in: labels above things.
  TextStyle get eyebrow =>
      _v(NewsType.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600), spacing: 0.6);

  @override
  AppType copyWith() => this;
  @override
  AppType lerp(AppType? other, double t) => this;
}

extension Themed on BuildContext {
  NewsColors get colors => Theme.of(this).extension<NewsColors>()!;
  AppType get type => Theme.of(this).extension<AppType>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  bool get still => MediaQuery.disableAnimationsOf(this);
}

/// "#rrggbb" as the API writes it, or nothing.
Color? colorOf(String hex) => RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)
    ? Color(0xFF000000 | int.parse(hex.substring(1), radix: 16))
    : null;

/// What sits over pictures and video is the same in every theme.
abstract final class OverMedia {
  static const ink = Color(0xFFFFFFFF);
  static const soft = Color(0xD9FFFFFF);
  static const faint = Color(0x66FFFFFF);
  static const ground = Color(0xFF000000);
  static const chip = Color(0xB3000000);
  static const scrim = Color(0x80000000);
  static const clear = Color(0x00000000);

  /// Dark enough at the foot for white text at 4.5:1 over a white picture.
  static const fade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.35, 0.7, 1],
    colors: [Color(0x00000000), Color(0x33000000), Color(0xB8000000), Color(0xE6000000)],
  );
  static const fadeTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xA6000000), Color(0x00000000)],
  );
  static const pill = Color(0xCC000000);
  static const bone = Color(0x33FFFFFF);
  static const night = Color(0xFF161616);

  /// The wall of pictures behind the welcome.
  static const wall = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.3, 0.56, 1],
    colors: [Color(0x66000000), Color(0x1A000000), Color(0xD9000000), Color(0xFF000000)],
  );

  /// Over a vertical video: the header above, the words below.
  static const short = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.18, 0.5, 0.78, 1],
    colors: [
      Color(0x80000000),
      Color(0x00000000),
      Color(0x26000000),
      Color(0xB8000000),
      Color(0xE6000000),
    ],
  );
  static const lift = [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))];
  static const shadow = [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))];
  static const textShadow = [Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1))];
}

ThemeData buildTheme(ThemeChoice choice, ThemeScheme scheme) {
  final c = choice.colors(scheme);
  final dark = scheme == ThemeScheme.dark;
  const type = AppType();
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: c.brand,
      onPrimary: c.onBrand,
      secondary: c.textPrimary,
      onSecondary: c.bg,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surface,
      onSurface: c.textPrimary,
      outline: c.borderStrong,
      outlineVariant: c.border,
    ),
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    fontFamily: 'Inter',
    splashFactory: InkSparkle.splashFactory,
    splashColor: c.textPrimary.withValues(alpha: 0.06),
    highlightColor: c.textPrimary.withValues(alpha: 0.04),
    extensions: [c, type],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.textPrimary,
      selectionColor: c.textPrimary.withValues(alpha: 0.18),
      selectionHandleColor: c.textPrimary,
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.textPrimary,
      contentTextStyle: type.label.copyWith(color: c.bg),
      actionTextColor: c.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NewsRadius.md)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceRaised,
      modalBackgroundColor: c.surfaceRaised,
      surfaceTintColor: OverMedia.clear,
      showDragHandle: true,
      dragHandleColor: c.borderStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(NewsRadius.xl)),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.textPrimary,
      inactiveTrackColor: c.border,
      thumbColor: c.textPrimary,
      overlayColor: c.textPrimary.withValues(alpha: 0.1),
      trackHeight: 3,
    ),
  );
}

/// Status and navigation bars that suit the ground beneath them.
SystemUiOverlayStyle overlayFor(Color ground) {
  final light = ground.computeLuminance() > 0.4;
  return (light ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light).copyWith(
    statusBarColor: OverMedia.clear,
    systemNavigationBarColor: OverMedia.clear,
    systemNavigationBarContrastEnforced: false,
    systemNavigationBarIconBrightness: light ? Brightness.dark : Brightness.light,
  );
}
