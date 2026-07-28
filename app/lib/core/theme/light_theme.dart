import 'package:flutter/material.dart';

// Executive Precision — color tokens
const _primary            = Color(0xFF000666);
const _onPrimary          = Color(0xFFFFFFFF);
const _primaryContainer   = Color(0xFF1A237E);
const _onPrimaryContainer = Color(0xFF8690EE);
const _inversePrimary     = Color(0xFFBDC2FF);

const _secondary            = Color(0xFF4355B9);
const _onSecondary          = Color(0xFFFFFFFF);
const _secondaryContainer   = Color(0xFF8596FF);
const _onSecondaryContainer = Color(0xFF11278E);

const _tertiary            = Color(0xFF181B23);
const _onTertiary          = Color(0xFFFFFFFF);
const _tertiaryContainer   = Color(0xFF2C3039);
const _onTertiaryContainer = Color(0xFF9597A2);

const _error            = Color(0xFFBA1A1A);
const _onError          = Color(0xFFFFFFFF);
const _errorContainer   = Color(0xFFFFDAD6);
const _onErrorContainer = Color(0xFF93000A);

const _surface           = Color(0xFFFCF9F8);
const _onSurface         = Color(0xFF1C1B1B);
const _surfaceVariant    = Color(0xFFE5E2E1);
const _onSurfaceVariant  = Color(0xFF454652);
const _inverseSurface    = Color(0xFF313030);
const _inverseOnSurface  = Color(0xFFF3F0EF);
const _surfaceTint       = Color(0xFF4C56AF);

const _outline         = Color(0xFF767683);
const _outlineVariant  = Color(0xFFC6C5D4);

// Level-1 ambient shadow (Navy 5%)
const _shadowColor = Color(0x0D000666);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Inter',

  colorScheme: const ColorScheme(
    brightness: Brightness.light,

    primary: _primary,
    onPrimary: _onPrimary,
    primaryContainer: _primaryContainer,
    onPrimaryContainer: _onPrimaryContainer,
    inversePrimary: _inversePrimary,

    secondary: _secondary,
    onSecondary: _onSecondary,
    secondaryContainer: _secondaryContainer,
    onSecondaryContainer: _onSecondaryContainer,

    tertiary: _tertiary,
    onTertiary: _onTertiary,
    tertiaryContainer: _tertiaryContainer,
    onTertiaryContainer: _onTertiaryContainer,

    error: _error,
    onError: _onError,
    errorContainer: _errorContainer,
    onErrorContainer: _onErrorContainer,

    surface: _surface,
    onSurface: _onSurface,
    surfaceContainerHighest: _surfaceVariant,
    onSurfaceVariant: _onSurfaceVariant,
    inverseSurface: _inverseSurface,
    onInverseSurface: _inverseOnSurface,
    surfaceTint: _surfaceTint,

    outline: _outline,
    outlineVariant: _outlineVariant,

    shadow: _shadowColor,
    scrim: Color(0x52000000),
  ),

  textTheme: const TextTheme(
    // headline-lg  32 / 600 / -0.02em
    displayLarge: TextStyle(
      fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600,
      height: 1.25, letterSpacing: -0.64,
    ),
    // headline-md  24 / 600 / -0.01em
    displayMedium: TextStyle(
      fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w600,
      height: 1.333, letterSpacing: -0.24,
    ),
    // headline-sm  20 / 500 / -0.01em
    displaySmall: TextStyle(
      fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w500,
      height: 1.4, letterSpacing: -0.20,
    ),
    // body-lg  16 / 400
    bodyLarge: TextStyle(
      fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    // body-md  14 / 400
    bodyMedium: TextStyle(
      fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400,
      height: 1.429,
    ),
    // body-sm  13 / 400
    bodySmall: TextStyle(
      fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400,
      height: 1.385,
    ),
    // label-md  12 / 600 / 0.05em  (uppercased at usage site)
    labelLarge: TextStyle(
      fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
      height: 1.333, letterSpacing: 0.6,
    ),
    // label-sm  11 / 500
    labelSmall: TextStyle(
      fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500,
      height: 1.273,
    ),
  ),

  // Cards — Level 1: white bg, 1px cool-gray border, soft ambient shadow
  cardTheme: CardThemeData(
    color: Color(0xFFFFFFFF),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      side: BorderSide(color: _outlineVariant, width: 1),
    ),
    shadowColor: _shadowColor,
    margin: EdgeInsets.zero,
  ),

  // Inputs — white bg, 1px border, 4px radius
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFFFFFFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: _outlineVariant),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: _outlineVariant),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(color: _secondary, width: 1),
    ),
    labelStyle: TextStyle(
      fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600,
      letterSpacing: 0.6, color: _onSurfaceVariant,
    ),
  ),

  // Buttons — Primary: solid navy, 4px radius
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _primaryContainer,
      foregroundColor: _onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: TextStyle(
        fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
      ),
    ),
  ),

  // Buttons — Secondary: outlined navy
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _primaryContainer,
      side: BorderSide(color: _primaryContainer),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: TextStyle(
        fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
      ),
    ),
  ),

  // Buttons — Ghost: no border/bg, indigo text
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _secondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      textStyle: TextStyle(
        fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600,
      ),
    ),
  ),

  // AppBar — white surface, navy foreground
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: _primaryContainer,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w600,
      letterSpacing: -0.20, color: _primaryContainer,
    ),
  ),

  // Dividers
  dividerTheme: const DividerThemeData(
    color: _outlineVariant,
    thickness: 1,
    space: 0,
  ),

  scaffoldBackgroundColor: _surface,
);
