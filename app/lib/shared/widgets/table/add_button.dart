import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Standard "add" button for a table's header, used across "Cadastros" pages.
class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.onPress, this.label = 'Adicionar'});

  final VoidCallback onPress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: FButtonVariant.primary,
      onPress: onPress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [Text(label)],
      ),
    );
  }
}
