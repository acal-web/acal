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
    (icon: Icons.people, label: 'Sócios', route: '/users'),
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
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: LayoutConfig.sideMenuWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isActive ? cs.primary : cs.onSurfaceVariant;
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
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
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
