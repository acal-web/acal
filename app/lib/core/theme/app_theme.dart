import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Square corners everywhere (cards, inputs, buttons, dialogs, ...) — every
/// Forui widget's default style derives its own decoration's radius from
/// this single token (see e.g. `FCardStyle.inherit`'s `style.borderRadius.lg`),
/// so overriding it here reskins the whole Forui side of the app at once.
const _squareRadius = FBorderRadius(
  xs2: BorderRadius.zero,
  xs: BorderRadius.zero,
  sm: BorderRadius.zero,
  md: BorderRadius.zero,
  lg: BorderRadius.zero,
  xl: BorderRadius.zero,
  xl2: BorderRadius.zero,
  xl3: BorderRadius.zero,
  pill: BorderRadius.zero,
);

/// Forui theme — the same `neutral` preset already validated on the
/// [DesignSystemDemoPage] design_system feature, with square corners.
final fThemeLight = _squared(FTheme.neutral.light.desktop, touch: false);
final fThemeDark = _squared(FTheme.neutral.dark.desktop, touch: false);

FThemeData _squared(FThemeData base, {required bool touch}) => FThemeData(
      colors: base.colors,
      touch: touch,
      style: base.style.copyWith(borderRadius: _squareRadius),
    );

/// Material theme for widgets that stay Material (e.g. [DataTableCard],
/// which has no Forui equivalent) — mirrors Forui's `neutral` color values
/// (`FColors.neutralLight`/`neutralDark`) so a Material table sitting next to
/// migrated Forui widgets doesn't clash (Flutter's own M3 default is purple).
final materialThemeLight = _materialTheme(
  brightness: Brightness.light,
  background: const Color(0xFFFFFFFF),
  foreground: const Color(0xFF0A0A0A),
  primary: const Color(0xFF171717),
  onPrimary: const Color(0xFFFAFAFA),
  secondary: const Color(0xFFF5F5F5),
  destructive: const Color(0xFFE7000B),
  onDestructive: const Color(0xFFFAFAFA),
  border: const Color(0xFFE5E5E5),
);

final materialThemeDark = _materialTheme(
  brightness: Brightness.dark,
  background: const Color(0xFF0A0A0A),
  foreground: const Color(0xFFFAFAFA),
  primary: const Color(0xFFE5E5E5),
  onPrimary: const Color(0xFF171717),
  secondary: const Color(0xFF262626),
  destructive: const Color(0xFFFF6467),
  onDestructive: const Color(0xFFFAFAFA),
  border: const Color(0x1AFFFFFF),
);

ThemeData _materialTheme({
  required Brightness brightness,
  required Color background,
  required Color foreground,
  required Color primary,
  required Color onPrimary,
  required Color secondary,
  required Color destructive,
  required Color onDestructive,
  required Color border,
}) {
  final colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness).copyWith(
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: foreground,
    error: destructive,
    onError: onDestructive,
    surface: background,
    onSurface: foreground,
    surfaceContainerHigh: secondary,
    outlineVariant: border,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    cardTheme: const CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
    dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
  );
}
