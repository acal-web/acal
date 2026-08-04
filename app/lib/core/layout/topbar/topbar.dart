import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_body.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_helpers.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_logo.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TopBarLogo(onMenuTap: onMenuTap),
              Expanded(child: TopBarBody()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: TopBarHelpers(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
