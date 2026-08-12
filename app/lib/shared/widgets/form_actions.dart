import 'package:flutter/material.dart' show Icons, IconData;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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
    this.readOnly = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;
  final String saveLabel;
  final IconData saveIcon;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FButton(variant: FButtonVariant.ghost, onPress: onCancel, child: const Text('Cancelar')),
        if (!readOnly) ...[
          const SizedBox(width: 8),
          FButton(
            onPress: saving ? null : onSave,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (saving)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FCircularProgress(size: FCircularProgressSizeVariant.xs),
                  )
                else ...[
                  Icon(saveIcon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(saveLabel),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
