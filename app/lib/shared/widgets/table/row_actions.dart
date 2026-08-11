import 'package:flutter/material.dart';

/// Standard edit/delete icon-button pair for a table row's "Ações" column,
/// used across "Cadastros" pages. When [active] is false, shows a reactivate
/// button instead of edit.
class RowActions extends StatelessWidget {
  const RowActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.active = true,
    this.onReactivate,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool active;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (active)
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Editar',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          )
        else if (onReactivate != null)
          IconButton(
            icon: const Icon(Icons.restore_outlined, size: 18),
            tooltip: 'Reativar',
            visualDensity: VisualDensity.compact,
            onPressed: onReactivate,
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Excluir',
          visualDensity: VisualDensity.compact,
          onPressed: onDelete,
        ),
      ],
    );
  }
}
