import 'package:flutter/material.dart';

/// Standard Cancelar/Salvar button row for a form dialog — the save button
/// shows a spinner while [saving] is true — used across "Cadastros" forms.
class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.saving,
    this.saveLabel = 'Salvar',
    this.saveIcon = Icons.save_outlined,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;
  final IconData saveIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: saving ? null : onSave,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(saveIcon, size: 18),
          label: Text(saveLabel),
        ),
      ],
    );
  }
}
