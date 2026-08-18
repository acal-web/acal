import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Standard "Excluir X?" confirmation dialog used across "Cadastros" pages
/// before a destructive delete action.
///
/// On narrow screens, displays as a bottom sheet; on wide screens, as a centered dialog.
Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final isNarrow =
      MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

  if (isNarrow) {
    // Use showModalBottomSheet directly for narrow screens to avoid FDialog padding
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: _buildDeleteContent(context, title, message),
      ),
    );
    return confirmed == true;
  }

  // On wide screens, use blurred dialog with FDialog
  final confirmed = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => FDialog(
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: _buildDeleteContent(context, title, message),
        ),
      ),
    ),
  );
  return confirmed == true;
}

Widget _buildDeleteContent(BuildContext context, String title, String message) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Text(message),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FButton(
            variant: FButtonVariant.ghost,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: 'confirm-delete-button',
            child: FButton(
              variant: FButtonVariant.destructive,
              onPress: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ),
        ],
      ),
    ],
  );
}
