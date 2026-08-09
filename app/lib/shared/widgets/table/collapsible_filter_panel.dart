import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';

/// Collapsed-by-default "Filtros" panel shared by every "Cadastros" list
/// page — a toggleable header that reveals [builder]'s content in a card
/// when expanded. Callers own their own field layout; this only owns the
/// expand/collapse chrome.
class CollapsibleFilterPanel extends StatefulWidget {
  const CollapsibleFilterPanel({super.key, required this.builder});

  final Widget Function(BuildContext context, bool narrow) builder;

  @override
  State<CollapsibleFilterPanel> createState() => _CollapsibleFilterPanelState();
}

class _CollapsibleFilterPanelState extends State<CollapsibleFilterPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < LayoutConfig.narrowBreakpoint;
        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: cs.surfaceContainerHigh,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(Icons.expand_more, size: 20),
                      ),
                      const SizedBox(width: 4),
                      Text('Filtros', style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          margin: EdgeInsets.zero,
                          color: cs.surfaceContainerHigh,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: LayoutConfig.pagePadding(narrow),
                            child: widget.builder(context, narrow),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
