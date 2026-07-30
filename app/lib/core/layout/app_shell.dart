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

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Scaffold(
        appBar: TopBar(onMenuTap: _toggleMenu),
        body: Row(
          children: [
            if (_menuVisible) const SideMenu(),
            Expanded(child: widget.body),
          ],
        ),
      ),
    );
  }
}
