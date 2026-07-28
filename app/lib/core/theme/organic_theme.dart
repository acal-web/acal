import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Organic — color tokens (see theme.json / styles.css in the "Organic" Claude
// design-system project this theme was imported from).
const _bg      = Color(0xFFF5EAD8);
const _surface = Color(0xFFEBDDC5);
const _text    = Color(0xFF201E1D);
const _accent  = Color(0xFFC67139);
const _accent2 = Color(0xFF7A8A5E);

// Neutral ramp (100-900), generated in OKLCH on a shared lightness scale.
const _neutral100 = Color(0xFFF9F4ED);
const _neutral200 = Color(0xFFEEE7DB);
const _neutral300 = Color(0xFFDCD3C4);
const _neutral400 = Color(0xFFC0B6A5);
const _neutral700 = Color(0xFF645C50);
const _neutral800 = Color(0xFF474238);
const _neutral900 = Color(0xFF2E2B25);

// Accent ramp (terracotta).
const _accent100 = Color(0xFFFFF2EB);
const _accent600 = Color(0xFFB2622D);
const _accent700 = Color(0xFF8C491A);
const _accent800 = Color(0xFF643312);

// Accent-2 ramp (sage) — the system's second voice.
const _accent2_100 = Color(0xFFF0FAE1);
const _accent2_800 = Color(0xFF3D472B);

// Divider — ink at 16% over the ground, per `--color-divider`.
final _divider = _text.withValues(alpha: 0.16);

/// Spacing scale (`--space-*`), density 1.1x already baked in.
abstract class OrganicSpacing {
  static const s1 = 4.4;
  static const s2 = 8.8;
  static const s3 = 13.2;
  static const s4 = 17.6;
  static const s6 = 26.4;
  static const s8 = 35.2;
}

/// Radius scale (`--radius-*`) plus the "rounded frame" overrides Organic
/// applies on top: containers go extra-round, small controls go full pill.
abstract class OrganicRadius {
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 28.0;
  static const container = 32.2; // --radius-lg * 1.15, used by .card / .dialog
  static const pill = 999.0; // .btn / .tag / .seg / .input
}

/// Elevation shadows (`--shadow-*`), ink-tinted for this light, warm ground.
abstract class OrganicShadows {
  static final sm = [
    BoxShadow(color: _neutral900.withValues(alpha: 0.14), offset: const Offset(0, 1), blurRadius: 2),
  ];
  static final md = [
    BoxShadow(color: _neutral900.withValues(alpha: 0.16), offset: const Offset(0, 3), blurRadius: 10),
  ];
  static final lg = [
    BoxShadow(color: _neutral900.withValues(alpha: 0.22), offset: const Offset(0, 12), blurRadius: 32),
  ];
}

TextStyle _heading(double fontSize, {double? letterSpacing, double? height}) =>
    GoogleFonts.caprasimo(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: letterSpacing ?? fontSize * -0.015,
      height: height ?? 1.12,
      color: _text,
    );

TextStyle _body(double fontSize, {FontWeight weight = FontWeight.w400, double? height, Color? color}) =>
    GoogleFonts.figtree(
      fontSize: fontSize,
      fontWeight: weight,
      height: height ?? 1.55,
      color: color ?? _text,
    );

final ThemeData organicTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  colorScheme: ColorScheme(
    brightness: Brightness.light,

    primary: _accent,
    onPrimary: _bg,
    primaryContainer: _accent100,
    onPrimaryContainer: _accent800,
    inversePrimary: _accent600,

    secondary: _accent2,
    onSecondary: _bg,
    secondaryContainer: _accent2_100,
    onSecondaryContainer: _accent2_800,

    tertiary: _text,
    onTertiary: _bg,
    tertiaryContainer: _neutral200,
    onTertiaryContainer: _neutral800,

    // Organic doesn't define a danger/error role; a standard Material red
    // keeps semantics unambiguous without fighting the warm palette.
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF93000A),

    surface: _surface,
    onSurface: _text,
    surfaceContainerHighest: _neutral300,
    onSurfaceVariant: _neutral700,
    inverseSurface: _neutral900,
    onInverseSurface: _neutral100,
    surfaceTint: _accent,

    outline: _neutral400,
    outlineVariant: _neutral300,

    shadow: _neutral900,
    scrim: _neutral900.withValues(alpha: 0.5),
  ),

  textTheme: TextTheme(
    displayLarge: _heading(42),  // h1
    displayMedium: _heading(32), // h2
    displaySmall: _heading(25),  // h3
    headlineMedium: _heading(20), // h4
    headlineSmall: _heading(16),  // h5
    titleSmall: _heading(13, letterSpacing: 13 * 0.08).copyWith(), // h6 — uppercase at usage site
    bodyLarge: _body(16),
    bodyMedium: _body(15), // matches the CSS body base size
    bodySmall: _body(13, color: _text.withValues(alpha: 0.55)),
    labelLarge: _body(14, weight: FontWeight.w600),
    labelMedium: _body(13, weight: FontWeight.w600),
    labelSmall: _body(11, weight: FontWeight.w600),
  ),

  // Cards — filled surface, no border, over-rounded per the "rounded frame".
  cardTheme: CardThemeData(
    color: _surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(OrganicRadius.container)),
    ),
    margin: EdgeInsets.zero,
  ),

  // Inputs — filled surface, pill-shaped, accent focus ring.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OrganicRadius.pill),
      borderSide: BorderSide(color: _divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OrganicRadius.pill),
      borderSide: BorderSide(color: _divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OrganicRadius.pill),
      borderSide: const BorderSide(color: _accent, width: 1),
    ),
    labelStyle: _body(12, color: _text.withValues(alpha: 0.7)),
  ),

  // Buttons — Primary: solid accent fill, pill shape, Caprasimo label.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return _accent700;
        if (states.contains(WidgetState.hovered)) return _accent600;
        return _accent;
      }),
      foregroundColor: const WidgetStatePropertyAll(_bg),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(OrganicRadius.pill)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: OrganicSpacing.s3 * 1.2, vertical: OrganicSpacing.s2),
      ),
      textStyle: WidgetStatePropertyAll(_heading(14, height: 1.2)),
    ),
  ),

  // Buttons — Secondary: divider-bordered outline, ink-tinted hover/pressed.
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(_text),
      side: WidgetStatePropertyAll(BorderSide(color: _divider)),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return _text.withValues(alpha: 0.14);
        if (states.contains(WidgetState.hovered)) return _text.withValues(alpha: 0.07);
        return null;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(OrganicRadius.pill)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: OrganicSpacing.s3 * 1.2, vertical: OrganicSpacing.s2),
      ),
      textStyle: WidgetStatePropertyAll(_heading(14, height: 1.2)),
    ),
  ),

  // Buttons — Ghost: accent text, no border/fill, accent-tinted hover/pressed.
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(_accent),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return _accent.withValues(alpha: 0.18);
        if (states.contains(WidgetState.hovered)) return _accent.withValues(alpha: 0.10);
        return null;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(OrganicRadius.pill)),
      ),
      textStyle: WidgetStatePropertyAll(_heading(14, height: 1.2)),
    ),
  ),

  // Nav — sits directly on the page ground, brand mark in Caprasimo.
  appBarTheme: AppBarTheme(
    backgroundColor: _bg,
    foregroundColor: _text,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: _heading(18, height: 1.2),
  ),

  dividerTheme: DividerThemeData(
    color: _divider,
    thickness: 1,
    space: OrganicSpacing.s4 * 2,
  ),

  scaffoldBackgroundColor: _bg,
);
