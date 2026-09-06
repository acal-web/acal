import 'package:flutter/material.dart';

/// Standard edit/delete icon-button pair for a table row's "Ações" column,
/// used across "Cadastros" pages. When [active] is false, shows a view-only
/// button instead of edit, and hides the delete button.
class RowActions extends StatelessWidget {
  const RowActions({
    super.key,
    required this.onEdit,
    required this.onDelete,
    this.active = true,
    this.onReactivate,
    this.onView,
  });

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool active;
  final VoidCallback? onReactivate;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (active)
          IconButton(
            key: const Key('row_action_edit'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Editar',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          )
        else if (onView != null)
          IconButton(
            key: const Key('row_action_view'),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            tooltip: 'Visualizar',
            visualDensity: VisualDensity.compact,
            onPressed: onView,
          ),
        if (!active && onReactivate != null)
          IconButton(
            key: const Key('row_action_reactivate'),
            icon: const Icon(Icons.restore_outlined, size: 18),
            tooltip: 'Reativar',
            visualDensity: VisualDensity.compact,
            onPressed: onReactivate,
          ),
        if (active)
          IconButton(
            key: const Key('row_action_delete'),
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Excluir',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
      ],
    );
  }
}
