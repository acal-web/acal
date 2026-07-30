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
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
