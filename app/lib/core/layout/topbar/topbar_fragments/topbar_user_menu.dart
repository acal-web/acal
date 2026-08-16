import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:flutter/material.dart';

class TopBarUserMenu extends StatelessWidget {
  const TopBarUserMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currentUser = CurrentUserScope.of(context);
    final user = currentUser.user;

    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'logout') {
          currentUser.logout();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primary,
              child: Text(
                user.username[0].toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    _roleLabel(user.role.value),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: cs.outline),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: cs.error),
              const SizedBox(width: 12),
              Text(
                'Sair',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'administrador':
        return 'Administrador';
      case 'financeiro_secretaria':
        return 'Financeiro/Secretaria';
      case 'tesoureiro':
        return 'Tesoureiro';
      default:
        return role;
    }
  }
}
