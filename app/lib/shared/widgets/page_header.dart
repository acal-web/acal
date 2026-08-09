import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, this.title, this.subtitle, this.action});

  final String? title;
  final String? subtitle;
  final Widget? action;

  // Below this width the title and action no longer fit comfortably on one
  // line, so they stack instead.
  static const _narrowBreakpoint = 480.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title!, style: theme.textTheme.displayMedium),
        if (title != null && subtitle != null) const SizedBox(height: 4),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _narrowBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (action != null) ...[
                const SizedBox(height: 8),
                action!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            ?action,
          ],
        );
      },
    );
  }
}
