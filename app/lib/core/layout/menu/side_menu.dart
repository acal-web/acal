import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _menuItems = [
  (icon: Icons.dashboard,   label: 'Dashboard',   route: '/dashboard'),
  (icon: Icons.people,      label: 'Users',       route: '/users'),
  (icon: Icons.location_on, label: 'Logradouros', route: '/addresses'),
];

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: LayoutConfig.sideMenuWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(right: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _menuItems
            .map((item) => _MenuItem(
                  icon: item.icon,
                  label: item.label,
                  route: item.route,
                  isActive: location == item.route,
                ))
            .toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isActive ? cs.onPrimary : cs.onSurfaceVariant;
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.w400;
    final backgroundColor = isActive ? cs.primary : Colors.transparent;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: fontWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
