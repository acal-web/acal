import 'package:flutter/material.dart';

class TopBarHelpers extends StatelessWidget {
  const TopBarHelpers({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: cs.onPrimary),
          onPressed: null,
        ),
      ],
    );
  }
}
