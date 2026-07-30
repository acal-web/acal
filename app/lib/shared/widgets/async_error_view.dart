import 'package:flutter/material.dart';

/// Standard "failed to load" state for a [FutureBuilder] — an error icon,
/// message, and retry button, used across "Cadastros" pages.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 40),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: cs.error)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
