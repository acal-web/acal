import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/layout/topbar/topbar.dart';
import 'package:acalapp/core/layout/menu/side_menu.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.body});

  final Widget body;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _menuVisible = true;
  bool? _lastIsNarrow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isNarrow = MediaQuery.sizeOf(context).width < LayoutConfig.menuBreakpoint;

    if (_lastIsNarrow != isNarrow) {
      _menuVisible = !isNarrow;
      _lastIsNarrow = isNarrow;
    }
  }

  void _toggleMenu() => setState(() => _menuVisible = !_menuVisible);
  void _closeMenu() => setState(() => _menuVisible = false);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < LayoutConfig.menuBreakpoint;

    return SelectionArea(
      child: Scaffold(
        appBar: TopBar(onMenuTap: _toggleMenu),
        // Desktop: the menu pushes the body over, sharing the row. Mobile:
        // the body keeps full width and the menu floats above it instead,
        // to avoid squeezing the content into an overflow.
        body: Stack(
          children: [
            Row(
              children: [
                if (_menuVisible && !isNarrow) const SideMenu(),
                Expanded(child: widget.body),
              ],
            ),
            if (_menuVisible && isNarrow) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMenu,
                  child: Container(color: Colors.black.withValues(alpha: 0.4)),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: SideMenu(onNavigate: _closeMenu),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
