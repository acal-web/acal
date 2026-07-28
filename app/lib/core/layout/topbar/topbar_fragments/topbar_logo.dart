import 'package:acalapp/core/config/app_config.dart';
import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';

class TopBarLogo extends StatelessWidget {
  const TopBarLogo({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: LayoutConfig.sideMenuWidth - 1,
      height: double.infinity,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.menu, color: cs.onSurface),
            onPressed: onMenuTap,
          ),
          Expanded(
            child: Text(
              AppConfig.appName,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
