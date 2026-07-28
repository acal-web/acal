import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';

class TopBarBody extends StatelessWidget {
  const TopBarBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < LayoutConfig.menuBreakpoint;

    if (isNarrow) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
