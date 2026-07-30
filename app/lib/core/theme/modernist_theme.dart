import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Modernist — color tokens (see theme.json / styles.css in the "Modernist"
// Claude design-system project this theme was imported from).
const _bg      = Color(0xFFF3F2F2);
const _surface = Color(0xFFEAE9E9);
const _text    = Color(0xFF201E1D);
// Mono scheme (hue 0, sat 0): accent is literally the text color, and its
// ramp is identical to the neutral ramp — there is no separate hue here.
const _accent  = Color(0xFF201E1D);
// accent-2 keeps its own warm-gray ramp, distinct from neutral/accent.
const _accent2 = Color(0xFF524D4A);

// Neutral ramp (100-900), generated in OKLCH on a shared lightness scale.
const _neutral100 = Color(0xFFF8F4F4);
const _neutral200 = Color(0xFFEAE7E7);
const _neutral300 = Color(0xFFD7D3D3);
const _neutral400 = Color(0xFFBAB6B6);
const _neutral700 = Color(0xFF605D5D);
const _neutral800 = Color(0xFF444141);
const _neutral900 = Color(0xFF2D2B2B);

// Accent ramp — equal to the neutral ramp (mono scheme, hue 0/sat 0).
const _accent100 = Color(0xFFF8F4F4);
const _accent600 = Color(0xFF7D7979);
const _accent700 = Color(0xFF605D5D);
const _accent800 = Color(0xFF444141);

// Accent-2 ramp — its own warm-gray steps, distinct from neutral/accent.
const _accent2_100 = Color(0xFFF5F4F3);
const _accent2_800 = Color(0xFF3A3634);

// Divider — strong ink at 40% over the ground, per `--color-divider`.
final _divider = _text.withValues(alpha: 0.40);

/// Spacing scale (`--space-*`), density 1.0x (no scaling).
abstract class ModernistSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}

/// Radius scale (`--radius-*`) — zero everywhere, on purpose. Nothing rounds.
abstract class ModernistRadius {
  static const sm = 0.0;
  static const md = 0.0;
  static const lg = 0.0;
}

/// Elevation shadows (`--shadow-*`), ink-tinted for this light ground.
abstract class ModernistShadows {
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
    GoogleFonts.archivo(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: letterSpacing ?? fontSize * -0.015,
      height: height ?? 1.12,
      color: _text,
    );

TextStyle _body(double fontSize, {FontWeight weight = FontWeight.w400, double? height, Color? color}) =>
    GoogleFonts.archivo(
      fontSize: fontSize,
      fontWeight: weight,
      height: height ?? 1.55,
      color: color ?? _text,
    );

final ThemeData modernistTheme = ThemeData(
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

    // Modernist doesn't define a danger/error role; a standard Material red
    // keeps semantics unambiguous even though it's close to this system's accent.
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
    titleSmall: _heading(13, letterSpacing: 13 * 0.08), // h6 — uppercase at usage site
    bodyLarge: _body(16),
    bodyMedium: _body(15), // matches the CSS body base size
    bodySmall: _body(13, color: _text.withValues(alpha: 0.55)),
    labelLarge: _body(14, weight: FontWeight.w600),
    labelMedium: _body(13, weight: FontWeight.w600),
    labelSmall: _body(11, weight: FontWeight.w600),
  ),

  // Cards — filled surface, square corners, no default shadow.
  cardTheme: CardThemeData(
    color: _surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ModernistRadius.md)),
    ),
    margin: EdgeInsets.zero,
  ),

  // Inputs — filled surface, square corners, strong divider border, accent focus ring.
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
    // Icons default to a 48px min-tap-target, which makes any field with a
    // prefixIcon taller than a plain field (e.g. a dropdown) — pin it down
    // so every input/combobox in the app lines up at the same height.
    prefixIconConstraints: const BoxConstraints(minWidth: 36),
    suffixIconConstraints: const BoxConstraints(minWidth: 36),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ModernistRadius.md),
      borderSide: BorderSide(color: _divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ModernistRadius.md),
      borderSide: BorderSide(color: _divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ModernistRadius.md),
      borderSide: const BorderSide(color: _accent, width: 1),
    ),
    labelStyle: _body(12, color: _text.withValues(alpha: 0.7)),
  ),

  // Buttons — Primary: solid accent fill, square corners, Archivo label.
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
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernistRadius.md)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: ModernistSpacing.s3 * 1.2, vertical: ModernistSpacing.s2),
      ),
      textStyle: WidgetStatePropertyAll(_heading(14, height: 1.2)),
    ),
  ),

  // Buttons — Filled: same as Primary/Elevated, for FilledButton call sites.
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return _accent700;
        if (states.contains(WidgetState.hovered)) return _accent600;
        return _accent;
      }),
      foregroundColor: const WidgetStatePropertyAll(_bg),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernistRadius.md)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: ModernistSpacing.s3 * 1.2, vertical: ModernistSpacing.s2),
      ),
      textStyle: WidgetStatePropertyAll(_heading(14, height: 1.2)),
    ),
  ),

  // Buttons — Secondary: strong divider-bordered outline, ink-tinted hover/pressed.
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
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernistRadius.md)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: ModernistSpacing.s3 * 1.2, vertical: ModernistSpacing.s2),
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
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(ModernistRadius.md)),
      ),
      textStyle: WidgetStatePropertyAll(_heading(14, height: 1.2)),
    ),
  ),

  // Dialogs/modals — filled surface, square corners, no default shadow.
  dialogTheme: DialogThemeData(
    backgroundColor: _bg,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ModernistRadius.lg)),
    ),
  ),

  // Nav — strong 2px divider along the bottom edge, brand mark in Archivo 800.
  appBarTheme: AppBarTheme(
    backgroundColor: _bg,
    foregroundColor: _text,
    elevation: 0,
    scrolledUnderElevation: 0,
    shape: Border(bottom: BorderSide(color: _divider, width: 2)),
    titleTextStyle: _heading(18, height: 1.2),
  ),

  // Strong 2px rules — this system uses dividers, not whitespace, to organize.
  dividerTheme: DividerThemeData(
    color: _divider,
    thickness: 2,
    space: ModernistSpacing.s4 * 2,
  ),

  scaffoldBackgroundColor: _bg,
);
