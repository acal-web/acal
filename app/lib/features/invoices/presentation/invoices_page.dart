import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice_period_filter_button.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

const _actionButtonWidth = 160.0;
const _dueDateColumnWidth = 110.0;
const _amountColumnWidth = 120.0;
const _actionsColumnWidth = 88.0;

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
  InvoicePeriod? _period;

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

  void _changePeriod(InvoicePeriod? period) => setState(() {
        _period = period;
        _page = 0;
        _future = _fetch();
      });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(narrow ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Faturas',
              subtitle: 'Cobranças emitidas para as ligações de água.',
              action: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: _actionButtonWidth,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/invoices/cobranca'),
                      icon: const Icon(Icons.mark_email_unread_outlined, size: 18),
                      label: const Text('Cobranças'),
                    ),
                  ),
                  SizedBox(
                    width: _actionButtonWidth,
                    child: FilledButton.icon(
                      onPressed: () => context.go('/invoices/generate'),
                      icon: const Icon(Icons.note_add, size: 18),
                      label: const Text('Gerar Faturas'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Filtrar por Período', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(width: 12),
                InvoicePeriodFilterButton(period: _period, onChanged: _changePeriod),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(narrow ? 12 : 16),
                  child: PagedListView<Invoice>(
                    future: _future,
                    columns: const [
                      DataTableColumn('Referência', flex: 1),
                      DataTableColumn('Sócio', flex: 3),
                      DataTableColumn('Ligação', flex: 3),
                      DataTableColumn('Vencimento', width: _dueDateColumnWidth),
                      DataTableColumn('Valor', width: _amountColumnWidth),
                      DataTableColumn('Ações', width: _actionsColumnWidth),
                    ],
                    emptyMessage: 'Nenhuma fatura emitida.',
                    errorMessage: 'Erro ao carregar faturas',
                    onRetry: _load,
                    onPageChanged: _goToPage,
                    pageSize: _pageSize,
                    onPageSizeChanged: _changePageSize,
                    rowBuilder: (context, invoice) => _InvoiceRow(invoice: invoice, service: _service, onChanged: _load),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatefulWidget {
  const _InvoiceRow({required this.invoice, required this.service, required this.onChanged});

  final Invoice invoice;
  final InvoiceService service;
  final VoidCallback onChanged;

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
      if (mounted) AppToast.error(context, 'Erro ao marcar a fatura como paga.');
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoice = widget.invoice;
    final connection = invoice.connection;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(formatMonthReference(invoice.referenceDate), style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Text(connection?.customer?.name ?? '—', style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: Text(
              connection == null
                  ? '—'
                  : '${connection.address?.fullAddress ?? '—'}, ${connection.number}${connection.letter ?? ''}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: _dueDateColumnWidth,
            child: Text(_formatDate(invoice.dueDate), style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: _amountColumnWidth,
            child: Text(formatBRL(invoice.amount), style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: _actionsColumnWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  tooltip: 'Baixar/imprimir boleto',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                  onPressed: _downloadPdf,
                ),
                if (invoice.isPaid)
                  const Tooltip(
                    message: 'Paga',
                    child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                  )
                else if (_marking)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.attach_money, size: 20),
                    tooltip: 'Marcar como paga',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                    onPressed: _markPaid,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
