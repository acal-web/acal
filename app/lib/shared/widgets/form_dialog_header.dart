import 'package:flutter/material.dart';

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
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
      ],
    );
  }
}
