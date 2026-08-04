import 'package:acalapp/shared/widgets/form_actions.dart';
import 'package:acalapp/shared/widgets/form_dialog_header.dart';
import 'package:flutter/material.dart';

/// The standard "Novo/Editar X" form dialog shell used across "Cadastros"
/// pages: a bounded [Dialog] wrapping a [Form] with a title/close header
/// and a Cancelar/Salvar action row. Close and Cancelar both pop `false`;
/// [onSave] is expected to pop `true` on success.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.formKey,
    required this.title,
    required this.fields,
    required this.onSave,
    required this.saving,
    this.maxWidth = 480,
    this.saveLabel = 'Salvar',
    this.saveIcon = Icons.save_outlined,
  });

  final GlobalKey<FormState> formKey;
  final String title;
  final Widget fields;
  final VoidCallback onSave;
  final bool saving;
  final double maxWidth;
  final String saveLabel;
  final IconData saveIcon;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormDialogHeader(
                  title: title,
                  onClose: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(height: 8),
                fields,
                const SizedBox(height: 16),
                FormActions(
                  onCancel: () => Navigator.of(context).pop(false),
                  onSave: onSave,
                  saving: saving,
                  saveLabel: saveLabel,
                  saveIcon: saveIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
