import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_body.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_helpers.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_logo.dart';
import 'package:flutter/material.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar({super.key, this.onMenuTap});

  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary,
      elevation: 1,
      shadowColor: Theme.of(context).colorScheme.onPrimary,
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
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
