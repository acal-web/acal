import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Standard "failed to load" state for a [FutureBuilder] — an error icon,
/// message, and retry button, used across "Cadastros" pages.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final style = context.theme.colors.destructive;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: style, size: 40),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: style)),
          const SizedBox(height: 8),
          FButton(variant: FButtonVariant.outline, onPress: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
