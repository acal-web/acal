import 'package:flutter/widgets.dart';

class LayoutConfig {
  static const double sideMenuWidth = 240;
  static const double menuBreakpoint = 768;

  /// Below this width, page layouts (filter bars, table pagination controls,
  /// action rows) stack vertically instead of side by side.
  static const double narrowBreakpoint = 640;

  /// Standard page/card padding, denser on narrow layouts.
  static EdgeInsets pagePadding(bool narrow) => EdgeInsets.all(narrow ? 12 : 16);
}