import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Eva — color tokens (see design_handoff_eva_design_system/design-system/
// tokens/colors.css, the "Acal Designer" Claude design-system this theme
// was imported from — Eva Design System / UI Kitten inspired), re-tinted
// dark following VS Code's classic "Dark (Visual Studio)" surface hierarchy —
// note this is the OPPOSITE relationship from that theme's newer "Dark
// Modern": here the editor (content — our cards/tables/dialogs) is the
// darkest layer (#1e1e1e), and the chrome around it (sideBar/activityBar —
// our topbar/side menu) sits one step lighter (#252526). Borders are also
// more visible than Dark Modern's near-invisible ones. Brand blue stays the
// app's primary.

// primary (brand blue) ramp — containers re-tinted dark, hover/pressed
// lightened instead of darkened (darkening a saturated blue toward black
// reads muddy on a dark surface).
const _primary100 = Color(0xFF16223F); // primaryContainer
const _primary200 = Color(0xFF1D2E52); // secondaryContainer
const _primary300 = Color(0xFFA6C1FF); // onPrimaryContainer / inversePrimary
const _primary500 = Color(0xFF3366FF); // primary (unchanged brand blue)
const _primary600 = Color(0xFF5580FF); // hover (lighter, not darker)
const _primary700 = Color(0xFF2952CC); // pressed
const _primary800 = Color(0xFFD6E4FF); // onSecondaryContainer

// semantic ramps — standard Material 3 dark error tokens (contrast-vetted).
const _dangerContainer = Color(0xFF93000A);
const _danger500 = Color(0xFFFFB4AB);
const _danger700 = Color(0xFFFFDAD6);

// basic (neutrals) — VS Code "Dark (Visual Studio)" inspired.
const _basic100 = Color(0xFF1E1E1E); // --color-surface (cards/tables/dialogs, like editor.background — darkest layer here)
const _basic200 = Color(0xFF252526); // --color-bg (page canvas + chrome, like sideBar.background — one step lighter)
const _basic300 = Color(0xFF2A2D2E); // hover tint / row stripe, like list.hoverBackground
const _basic400 = Color(0xFF454545); // --color-border, like the classic theme's visible contrast borders
const _basic500 = Color(0xFF6B6B6B); // outline, a step stronger than _basic400
const _basic600 = Color(0xFF9D9D9D); // --color-text-hint, muted grey like editorLineNumber.foreground
const _basic700 = Color(0xFFCCCCCC); // medium-emphasis text/icon
const _basic900 = Color(0xFFD4D4D4); // --color-text primary/headings, this theme's actual "foreground" token

// Shadows are ink-tinted; on a dark surface pure black reads better than
// the old basic-900 tint (which is now a light color).
const _shadowColor = Color(0xFF000000);

/// Spacing scale (`--space-*`), 4px base.
abstract class EvaSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s7 = 32.0;
  static const s8 = 40.0;
}

/// Radius scale (`--radius-*`) — zero everywhere, on purpose (square corners).
abstract class EvaRadius {
  static const sm = 0.0;
  static const md = 0.0;
  static const lg = 0.0;
}

/// Elevation shadows (`--shadow-*`).
abstract class EvaShadows {
  static final sm = [
    BoxShadow(color: _shadowColor.withValues(alpha: 0.06), offset: const Offset(0, 2), blurRadius: 8),
  ];
  static final md = [
    BoxShadow(color: _shadowColor.withValues(alpha: 0.10), offset: const Offset(0, 6), blurRadius: 14),
  ];
  static final lg = [
    BoxShadow(color: _shadowColor.withValues(alpha: 0.14), offset: const Offset(0, 12), blurRadius: 28),
  ];
}

TextStyle _heading(double fontSize, {FontWeight weight = FontWeight.w700, double? letterSpacing, double? height}) =>
    GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height ?? 1.25,
      color: _basic900,
    );

TextStyle _body(double fontSize, {FontWeight weight = FontWeight.w400, double? height, Color? color}) =>
    GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: weight,
      height: height ?? 1.45,
      color: color ?? _basic900,
    );

// Inputs — bg fill, square corners, border, primary focus ring. Reused for
// both ThemeData.inputDecorationTheme and ThemeData.dropdownMenuTheme below:
// DropdownMenu (used by AddressSelectField/CategorySelectField) doesn't pick
// up ThemeData.inputDecorationTheme on its own — it reads a separate
// DropdownMenuTheme that defaults to Flutter's stock (light) input styling
// when unset, which is why those fields looked mismatched in dark mode.
final _inputDecorationTheme = InputDecorationTheme(
  filled: true,
  fillColor: _basic200,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  prefixIconConstraints: const BoxConstraints(minWidth: 36),
  suffixIconConstraints: const BoxConstraints(minWidth: 36),
  border: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md)),
    borderSide: BorderSide(color: _basic400),
  ),
  enabledBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md)),
    borderSide: BorderSide(color: _basic400),
  ),
  focusedBorder: const OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md)),
    borderSide: BorderSide(color: _primary500, width: 2),
  ),
  labelStyle: _body(12, weight: FontWeight.w600, color: _basic600),
  hintStyle: _body(14, color: _basic600),
);

final ThemeData evaTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,

  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    primary: _primary500,
    onPrimary: Colors.white,
    primaryContainer: _primary100,
    onPrimaryContainer: _primary300,
    inversePrimary: _primary300,

    secondary: _primary600,
    onSecondary: Colors.white,
    secondaryContainer: _primary200,
    onSecondaryContainer: _primary800,

    // tertiary is dark-on-light in the old light theme (onTertiaryContainer
    // is read directly by side_menu.dart as the inactive nav-icon color, so
    // it must stay legible on the dark _basic300 tertiaryContainer below).
    tertiary: _basic900,
    onTertiary: _basic200,
    tertiaryContainer: _basic300,
    onTertiaryContainer: _basic700,

    error: _danger500,
    onError: Color(0xFF690005),
    errorContainer: _dangerContainer,
    onErrorContainer: _danger700,

    surface: _basic100,
    onSurface: _basic900,
    surfaceContainerHighest: _basic300,
    onSurfaceVariant: _basic600,
    inverseSurface: _basic900,
    onInverseSurface: _basic100,
    surfaceTint: _primary500,

    outline: _basic500,
    outlineVariant: _basic400,

    shadow: _shadowColor,
    scrim: Color(0x52000000),
  ),

  textTheme: TextTheme(
    displayLarge: _heading(40, weight: FontWeight.w800),  // display
    displayMedium: _heading(30, weight: FontWeight.w700), // 2xl
    displaySmall: _heading(24, weight: FontWeight.w700),  // xl
    headlineMedium: _heading(20, weight: FontWeight.w600), // lg
    headlineSmall: _heading(16, weight: FontWeight.w600),  // md
    titleSmall: _heading(13, weight: FontWeight.w700, letterSpacing: 13 * 0.04), // sm, eyebrow
    bodyLarge: _body(16),
    bodyMedium: _body(14),
    bodySmall: _body(13, color: _basic600),
    labelLarge: _body(14, weight: FontWeight.w700),  // buttons
    labelMedium: _body(13, weight: FontWeight.w700),
    labelSmall: _body(12, weight: FontWeight.w700),  // badges
  ),

  // Cards — dark surface, square corners, no border, elevation by shadow only.
  cardTheme: CardThemeData(
    color: _basic100,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(EvaRadius.lg)),
    ),
    shadowColor: _shadowColor,
    margin: EdgeInsets.zero,
  ),

  inputDecorationTheme: _inputDecorationTheme,

  // See _inputDecorationTheme's doc comment above for why this is needed.
  dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: _inputDecorationTheme),

  // Buttons — Primary: solid brand blue, square corners.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return _primary500.withValues(alpha: 0.45);
        if (states.contains(WidgetState.pressed)) return _primary700;
        if (states.contains(WidgetState.hovered)) return _primary600;
        return _primary500;
      }),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(0),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md))),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: EvaSpacing.s5 - 2, vertical: EvaSpacing.s3),
      ),
      textStyle: WidgetStatePropertyAll(_body(14, weight: FontWeight.w700)),
    ),
  ),

  // Buttons — Filled: same as Primary/Elevated, for FilledButton call sites.
  filledButtonTheme: FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return _primary500.withValues(alpha: 0.45);
        if (states.contains(WidgetState.pressed)) return _primary700;
        if (states.contains(WidgetState.hovered)) return _primary600;
        return _primary500;
      }),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(0),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md))),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: EvaSpacing.s5 - 2, vertical: EvaSpacing.s3),
      ),
      textStyle: WidgetStatePropertyAll(_body(14, weight: FontWeight.w700)),
    ),
  ),

  // Buttons — Outline: brand blue text, light brand border.
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(_primary500),
      side: const WidgetStatePropertyAll(BorderSide(color: _primary300)),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return _primary500.withValues(alpha: 0.14);
        if (states.contains(WidgetState.hovered)) return _primary500.withValues(alpha: 0.07);
        return null;
      }),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md))),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: EvaSpacing.s5 - 2, vertical: EvaSpacing.s3),
      ),
      textStyle: WidgetStatePropertyAll(_body(14, weight: FontWeight.w700)),
    ),
  ),

  // Buttons — Ghost: plain text color, no border/fill.
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: const WidgetStatePropertyAll(_basic900),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return _basic900.withValues(alpha: 0.10);
        if (states.contains(WidgetState.hovered)) return _basic900.withValues(alpha: 0.05);
        return null;
      }),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(EvaRadius.md))),
      ),
      textStyle: WidgetStatePropertyAll(_body(14, weight: FontWeight.w700)),
    ),
  ),

  // Dialogs/modals — dark surface, square corners.
  dialogTheme: DialogThemeData(
    backgroundColor: _basic100,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(EvaRadius.lg)),
    ),
  ),

  // AppBar — dark surface, light ink foreground.
  appBarTheme: AppBarTheme(
    backgroundColor: _basic100,
    foregroundColor: _basic900,
    elevation: 0,
    scrolledUnderElevation: 0,
    shape: const Border(bottom: BorderSide(color: _basic400, width: 1)),
    titleTextStyle: _heading(20, weight: FontWeight.w600),
  ),

  dividerTheme: const DividerThemeData(
    color: _basic400,
    thickness: 1,
    space: 0,
  ),

  scaffoldBackgroundColor: _basic200,
);
