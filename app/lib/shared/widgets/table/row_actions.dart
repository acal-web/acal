import 'package:flutter/material.dart';

/// Standard edit/delete icon-button pair for a table row's "Ações" column,
/// used across "Cadastros" pages.
class RowActions extends StatelessWidget {
  const RowActions({super.key, required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
        ),
      ],
    );
  }
}
