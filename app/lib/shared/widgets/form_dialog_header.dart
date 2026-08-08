import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Standard title + close-button row for a "Novo/Editar X" form dialog,
/// used across "Cadastros" pages.
class FormDialogHeader extends StatelessWidget {
  const FormDialogHeader({super.key, required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        FButton(
          variant: FButtonVariant.ghost,
          size: FButtonSizeVariant.sm,
          mainAxisSize: MainAxisSize.min,
          onPress: onClose,
          child: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }
}
