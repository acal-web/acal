import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

const columnSpacing = 12.0;

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key, this.invoiceService});

  final InvoiceService? invoiceService;

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  late final InvoiceService _service;
  late Future<PagedResult<Invoice>> _future;
  int _page = 0;
  int _pageSize = 10;
  MonthYear? _period;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _future = _fetch();
  }

  Future<PagedResult<Invoice>> _fetch() => _service.findAll(
    page: _page,
    size: _pageSize,
    year: _period?.year,
    month: _period?.month,
  );

  void _load() => setState(() {
    _future = _fetch();
  });

  void _goToPage(int page) => setState(() {
    _page = page;
    _future = _fetch();
  });

  void _changePageSize(int size) => setState(() {
    _pageSize = size;
    _page = 0;
    _future = _fetch();
  });

  void _changePeriod(MonthYear? period) => setState(() {
    _period = period;
    _page = 0;
    _future = _fetch();
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              subtitle: 'Cobranças emitidas para as ligações de água.',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => context.go('/invoices/cobranca'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mark_email_unread_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Cobranças'),
                      ],
                    ),
                  ),
                  FButton(
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => context.go('/invoices/generate'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.note_add, size: 18),
                        SizedBox(width: 8),
                        Text('Gerar Faturas'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Filtrar por Período',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  PeriodFilterButton(
                    period: _period,
                    onChanged: _changePeriod,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<PagedResult<Invoice>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Erro ao carregar faturas'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data;
                  if (data == null || data.data.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma fatura emitida.'),
                    );
                  }

                  return Column(
                    children: [
                      _TableHeader(onPageSizeChanged: _changePageSize),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: data.data.length,
                          addRepaintBoundaries: true,
                          addSemanticIndexes: false,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final invoice = data.data[index];
                            final isEven = index.isEven;

                            return _InvoiceRow(
                              invoice: invoice,
                              service: _service,
                              onChanged: _load,
                              isEven: isEven,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FutureBuilder<PagedResult<Invoice>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final data = snapshot.data!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mostrando ${data.data.length} de ${data.pagination.totalElements} registros',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _page > 0 ? () => _goToPage(_page - 1) : null,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: 'Página anterior',
                          ),
                          Text(
                            'Página ${_page + 1} de ${data.pagination.totalPages}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            onPressed: !data.pagination.last ? () => _goToPage(_page + 1) : null,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: 'Próxima página',
                          ),
                        ],
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

class _TableHeader extends StatelessWidget {
  final Function(int) onPageSizeChanged;

  const _TableHeader({required this.onPageSizeChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        spacing: columnSpacing,
        children: [
          Expanded(
            flex: 1,
            child: Text('Referência', style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text('Sócio', style: headerStyle),
          ),
          Expanded(
            flex: 3,
            child: Text('Ligação', style: headerStyle),
          ),
          SizedBox(
            width: 110,
            child: Text('Vencimento', style: headerStyle),
          ),
          SizedBox(
            width: 120,
            child: Text('Valor', style: headerStyle),
          ),
          SizedBox(
            width: 88,
            child: Text('Ações', style: headerStyle),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatefulWidget {
  const _InvoiceRow({
    required this.invoice,
    required this.service,
    required this.onChanged,
    this.isEven = false,
  });

  final Invoice invoice;
  final InvoiceService service;
  final VoidCallback onChanged;
  final bool isEven;

  @override
  State<_InvoiceRow> createState() => _InvoiceRowState();
}

class _InvoiceRowState extends State<_InvoiceRow> {
  bool _marking = false;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _downloadPdf() async {
    final id = widget.invoice.id;
    if (id == null) return;
    try {
      await Printing.layoutPdf(onLayout: (_) => widget.service.pdf(id));
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao gerar o PDF da fatura.');
    }
  }

  Future<void> _markPaid() async {
    final id = widget.invoice.id;
    if (id == null) return;
    setState(() => _marking = true);
    try {
      await widget.service.markPaid(id);
      if (mounted) {
        AppToast.success(context, 'Fatura marcada como paga.');
        widget.onChanged();
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Erro ao marcar a fatura como paga.');
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoice = widget.invoice;
    final connection = invoice.connection;
    final backgroundColor = widget.isEven
        ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainer.withValues(alpha: 0.4);

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                formatMonthReference(invoice.referenceDate),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                connection?.customer?.name ?? '—',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                connection == null
                    ? '—'
                    : '${connection.address?.name ?? '—'}, ${connection.number}${connection.letter ?? ''}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                _formatDate(invoice.dueDate),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                formatBRL(invoice.amount),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 88,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    semanticsTooltip: 'Baixar/imprimir boleto',
                    onPress: _downloadPdf,
                    child: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  ),
                  if (invoice.isPaid)
                    FTooltip(
                      tipBuilder: (context, controller) => const Text('Paga'),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    )
                  else if (_marking)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: FCircularProgress(),
                      ),
                    )
                  else
                    FButton(
                      variant: FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      mainAxisSize: MainAxisSize.min,
                      semanticsTooltip: 'Marcar como paga',
                      onPress: _markPaid,
                      child: const Icon(Icons.attach_money, size: 20),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
