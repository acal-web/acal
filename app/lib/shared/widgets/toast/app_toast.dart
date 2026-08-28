import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum AppToastType { error, warning, success }

/// Global floating toast — shows error/warning/confirmation messages docked
/// to the bottom-right of the screen, above dialogs, auto-dismissing after
/// [duration]. Call from anywhere with a [BuildContext] under the app's
/// [FToaster] (mounted once in `main.dart`).
///
/// Bottom-right, not top-right: forui's toast hit-tests a region sized for
/// its enter/exit animation, not just the visible pill, and that region can
/// outlive/outsize the pill and swallow taps on whatever sits underneath.
/// Top-right is exactly where [TopBarUserMenu] lives, so every toast made
/// the user menu unresponsive while showing. Bottom-right has no persistent
/// interactive chrome under it.
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
    // Forui's toast variants only cover primary/destructive — warning and
    // success reuse primary and lean on the icon to carry the distinction.
    final (variant, icon) = switch (type) {
      AppToastType.error => (FToastVariant.destructive, Icons.error_outline),
      AppToastType.warning => (FToastVariant.primary, Icons.warning_amber_outlined),
      AppToastType.success => (FToastVariant.primary, Icons.check_circle_outline),
    };

    showFToast(
      context: context,
      variant: variant,
      icon: Icon(icon),
      title: Text(message),
      suffixBuilder: (context, entry) => FButton(
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        semanticsTooltip: 'Fechar',
        onPress: entry.dismiss,
        child: const Icon(Icons.close, size: 16),
      ),
      alignment: FToastAlignment.bottomRight,
      duration: duration,
    );
  }
}
