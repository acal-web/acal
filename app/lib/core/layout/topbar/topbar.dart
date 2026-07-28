import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_body.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_helpers.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_logo.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
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
                padding: EdgeInsets.symmetric(horizontal: 16),
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
