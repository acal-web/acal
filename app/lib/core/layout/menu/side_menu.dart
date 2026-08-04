import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef _MenuItemData = ({IconData icon, String label, String route});

class _MenuSection {
  const _MenuSection({this.title, required this.items});

  final String? title;
  final List<_MenuItemData> items;
}

const _menuSections = [
  _MenuSection(items: [
    (icon: Icons.home, label: 'Home', route: '/dashboard'),
  ]),
  _MenuSection(title: 'CADASTROS', items: [
    (icon: Icons.people, label: 'Sócios', route: '/customers'),
    (icon: Icons.location_on, label: 'Logradouros', route: '/addresses'),
    (icon: Icons.category, label: 'Categorias', route: '/categories'),
  ]),
  _MenuSection(title: 'ÁGUA', items: [
    (icon: Icons.water_drop, label: 'Ligações', route: '/connections'),
    (icon: Icons.straighten, label: 'Qualidade', route: '/quality'),
  ]),
  _MenuSection(title: 'FINANCEIRO', items: [
    (icon: Icons.note_add, label: 'Gerar Faturas', route: '/invoices/generate'),
    (icon: Icons.receipt_long, label: 'Faturas', route: '/invoices'),
    (icon: Icons.point_of_sale, label: 'Caixa', route: '/cashbox'),
  ]),
  _MenuSection(title: 'ADMINISTRAÇÃO', items: [
    (icon: Icons.how_to_vote, label: 'Eleição', route: '/elections'),
    (icon: Icons.article, label: 'Documentação', route: '/documentation'),
  ]),
];

class SideMenu extends StatelessWidget {
  const SideMenu({super.key, this.onNavigate});

  /// Called after a menu item navigates — used to dismiss the menu when it's
  /// shown as a mobile overlay (unused on desktop, where it stays open).
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: LayoutConfig.sideMenuWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(right: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in _menuSections) ...[
              if (section.title != null) _SectionHeader(title: section.title!),
              ...section.items.map((item) => _MenuItem(
                    icon: item.icon,
                    label: item.label,
                    route: item.route,
                    isActive: location == item.route,
                    onNavigate: onNavigate,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
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
    this.onNavigate,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isActive ? cs.primary : cs.onSurfaceVariant;
    // The icon reads too light against onSurfaceVariant alone — bump it to a
    // darker neutral so it doesn't wash out next to the label text.
    final iconColor = isActive ? cs.primary : cs.onTertiaryContainer;
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.w400;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive ? cs.primary.withValues(alpha: 0.12) : null,
        border: Border(
          left: BorderSide(
            color: isActive ? cs.primary : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go(route);
            onNavigate?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontWeight: fontWeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
