import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';

class TopBarBody extends StatelessWidget {
  const TopBarBody({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
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
                child: TextField(
                  style: TextStyle(color: theme.onPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: theme.onPrimary),
                    prefixIcon: Icon(Icons.search, color: theme.onPrimary),
                    filled: true,
                    fillColor: theme.primaryContainer,
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.onPrimary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.onPrimary.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
