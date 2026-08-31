import 'package:flutter/material.dart';

enum AppToastType { error, warning, success }

/// Global floating toast — shows error/warning/confirmation messages via a
/// standard Material [SnackBar], anchored to the nearest [ScaffoldMessenger].
/// Call from anywhere with a [BuildContext] under a [Scaffold].
///
/// This used to be built on forui's `FToaster`/`showFToast`, which renders
/// its own floating overlay on top of the app. That overlay's hit-testable
/// area didn't match its visible size, and repeatedly ended up swallowing
/// clicks on menus underneath it — moving the toast around the screen never
/// fully fixed it, so it was replaced outright with the plain SnackBar,
/// which has no overlay of its own and lives inside the Scaffold.
abstract final class AppToast {
  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.warning);

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.success);

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = switch (type) {
      AppToastType.error => (Icons.error_outline, cs.error),
      AppToastType.warning => (Icons.warning_amber_outlined, Colors.amber.shade800),
      AppToastType.success => (Icons.check_circle_outline, Colors.green.shade700),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
