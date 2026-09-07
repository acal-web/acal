import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Dashboard',
              subtitle: 'Resumo financeiro.',
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
