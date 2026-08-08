import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Standard "Excluir X?" confirmation dialog used across "Cadastros" pages
/// before a destructive delete action.
Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final confirmed = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => FDialog(
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(16),
        // Caps the dialog's width so a long message (e.g. a long address
        // name) wraps instead of stretching the dialog across the screen.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
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
          ),
        ),
      ),
    ),
  );
  return confirmed == true;
}
