import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/dashboard/data/dashboard_service.dart';
import 'package:acalapp/features/dashboard/domain/dashboard_summary.dart';
import 'package:acalapp/features/dashboard/widget/category_donut_chart.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.dashboardService});

  final DashboardService? dashboardService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardService _service;
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.dashboardService ?? DashboardService();
    _future = _service.summary();
  }

  void _reload() => setState(() => _future = _service.summary());

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Visão Geral',
              subtitle: 'Bem-vindo de volta. Aqui está o resumo financeiro de hoje.',
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<DashboardSummary>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AsyncErrorView(
                      message: 'Erro ao carregar resumo financeiro',
                      onRetry: _reload,
                    );
                  }

                  final data = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatCards(context, data, narrow),
                        const SizedBox(height: 24),
                        if (narrow)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRecentTransactions(context, data),
                              const SizedBox(height: 24),
                              _buildMembersByCategory(context, data),
                              const SizedBox(height: 24),
                              _buildQuickActions(context),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildRecentTransactions(context, data),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _buildMembersByCategory(context, data),
                                    const SizedBox(height: 24),
                                    _buildQuickActions(context),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, DashboardSummary data, bool narrow) {
    final today = DateTime.now();
    final monthYear = '${today.month.toString().padLeft(2, '0')}/${today.year}';

    if (narrow) {
      return GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            label: 'Total Recebido em $monthYear',
            value: formatBRL(data.totalReceived),
            icon: Icons.trending_up,
          ),
          StatCard(
            label: 'Total a Receber',
            value: formatBRL(data.totalReceivable),
            icon: Icons.trending_down,
          ),
          StatCard(
            label: 'Faturas a Receber',
            value: '${data.invoicesReceivableCount}',
            icon: Icons.receipt,
          ),
          StatCard(
            label: 'Faturas Pagas',
            value: '${data.invoicesReceivedCount}',
            icon: Icons.check_circle,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StatCard(
            label: 'Total Recebido em $monthYear',
            value: formatBRL(data.totalReceived),
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Total a Receber',
            value: formatBRL(data.totalReceivable),
            icon: Icons.trending_down,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Faturas a Receber',
            value: '${data.invoicesReceivableCount}',
            icon: Icons.receipt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Faturas Pagas',
            value: '${data.invoicesReceivedCount}',
            icon: Icons.check_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, DashboardSummary data) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transações Recentes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/invoices'),
                  child: Text(
                    'Ver todas',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (data.recentInvoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhuma transação recente',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.recentInvoices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final invoice = data.recentInvoices[i];
                final customerName = invoice.connection?.customer?.name ?? '-';
                final isPaid = invoice.isPaid;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoice.referenceDate.toIso8601String().split('T')[0],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatBRL(invoice.amount),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? cs.primary.withValues(alpha: 0.1)
                              : cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPaid ? 'Pago' : 'Aberto',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isPaid ? cs.primary : cs.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMembersByCategory(BuildContext context, DashboardSummary data) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sócios por Categoria',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: CategoryDonutChart(membersByCategory: data.membersByCategory),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ações Rápidas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.add_circle_outline,
            label: 'Novo Recebível',
            onTap: () => context.go('/invoices/generate'),
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.download_outlined,
            label: 'Relatório Financeiro',
            enabled: false,
          ),
          const Divider(height: 1),
          _QuickActionItem(
            icon: Icons.people_outline,
            label: 'Gerenciar Clientes',
            onTap: () => context.go('/customers'),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? cs.primary : cs.outlineVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: enabled ? cs.onSurface : cs.outlineVariant,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: enabled ? cs.outlineVariant : cs.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
