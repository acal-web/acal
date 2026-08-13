import 'package:flutter/material.dart';

class InvalidDataBadge extends StatelessWidget {
  final bool hasInvalidData;

  const InvalidDataBadge({
    super.key,
    required this.hasInvalidData,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasInvalidData) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Dados Inválidos',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
