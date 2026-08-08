import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/overdue_connection.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:printing/printing.dart';

const _countColumnWidth = 90.0;
const _totalColumnWidth = 130.0;
const _actionColumnWidth = 56.0;

/// Lists connections with unpaid invoices overdue by more than a threshold,
/// letting the user download the dunning letter (carta de cobrança) for one
/// connection or for all of them at once — mirrors the legacy rc_cobranca
/// report family, driven off `GET /invoices/overdue` + `GET /invoices/cobranca_pdf`.
class CobrancaPage extends StatefulWidget {
  const CobrancaPage({super.key, this.invoiceService});

  final InvoiceService? invoiceService;

  @override
  State<CobrancaPage> createState() => _CobrancaPageState();
}

class _CobrancaPageState extends State<CobrancaPage> {
  late final InvoiceService _service;
  int _days = 30;
  late Future<List<OverdueConnection>> _future;
  bool _downloadingAll = false;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _future = _fetch();
  }

  Future<List<OverdueConnection>> _fetch() => _service.overdue(days: _days);

  void _reload() => setState(() => _future = _fetch());

  void _changeDays(int? days) {
    if (days == null) return;
    setState(() {
      _days = days;
      _future = _fetch();
    });
  }

  Future<void> _downloadOne(String connectionId) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => _service.cobrancaPdf(connectionId: connectionId, days: _days));
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao gerar a carta de cobrança.');
    }
  }

  Future<void> _downloadAll() async {
    setState(() => _downloadingAll = true);
    try {
      await Printing.layoutPdf(onLayout: (_) => _service.cobrancaPdf(days: _days));
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao gerar as cartas de cobrança.');
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(narrow ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Cobranças',
              subtitle: 'Cartas de aviso para ligações com faturas vencidas e não pagas.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Vencidas há mais de', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: FSelect<int>(
                    items: const {'30 dias': 30, '60 dias': 60, '90 dias': 90},
                    control: FSelectControl.managed(initial: _days, onChange: _changeDays),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<OverdueConnection>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: FCircularProgress());
                  }
                  if (snapshot.hasError) {
                    return AsyncErrorView(message: 'Erro ao carregar cobranças em aberto', onRetry: _reload);
                  }

                  final groups = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _OverdueCard(groups: groups, onDownload: _downloadOne)),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FButton(
                          mainAxisSize: MainAxisSize.min,
                          onPress: groups.isEmpty || _downloadingAll ? null : _downloadAll,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mark_email_read_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text(_downloadingAll ? 'Gerando...' : 'Baixar Todas as Cartas'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  const _OverdueCard({required this.groups, required this.onDownload});

  final List<OverdueConnection> groups;
  final void Function(String connectionId) onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('SÓCIO', style: theme.textTheme.labelLarge)),
                Expanded(flex: 3, child: Text('LIGAÇÃO', style: theme.textTheme.labelLarge)),
                SizedBox(width: _countColumnWidth, child: Text('FATURAS', style: theme.textTheme.labelLarge)),
                SizedBox(width: _totalColumnWidth, child: Text('TOTAL', style: theme.textTheme.labelLarge)),
                const SizedBox(width: _actionColumnWidth),
              ],
            ),
          ),
          const Divider(height: 1),
          if (groups.isEmpty)
            const Expanded(child: Center(child: Text('Nenhuma fatura vencida encontrada.')))
          else
            Expanded(
              child: ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final group = groups[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(group.customerName)),
                        Expanded(flex: 3, child: Text('${group.addressName}, ${group.connectionNumber}')),
                        SizedBox(width: _countColumnWidth, child: Text('${group.invoices.length}')),
                        SizedBox(width: _totalColumnWidth, child: Text(formatBRL(group.totalAmount))),
                        SizedBox(
                          width: _actionColumnWidth,
                          child: FButton(
                            variant: FButtonVariant.ghost,
                            size: FButtonSizeVariant.sm,
                            mainAxisSize: MainAxisSize.min,
                            semanticsTooltip: 'Baixar carta de cobrança',
                            onPress: () => onDownload(group.connectionId),
                            child: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
