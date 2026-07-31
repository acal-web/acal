import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

/// Standard "Excluir X?" confirmation dialog used across "Cadastros" pages
/// before a destructive delete action.
Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final confirmed = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        // Caps the dialog's width so a long message (e.g. a long address
        // name) wraps instead of stretching the dialog across the screen.
        constraints: const BoxConstraints(maxWidth: 320),
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        Semantics(
          identifier: 'confirm-delete-button',
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
