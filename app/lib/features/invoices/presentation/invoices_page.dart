import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice_period_filter_button.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _actionButtonWidth = 200.0;
const _dueDateColumnWidth = 110.0;
const _amountColumnWidth = 120.0;

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
              action: SizedBox(
                width: _actionButtonWidth,
                child: FilledButton.icon(
                  onPressed: () => context.go('/invoices/generate'),
                  icon: const Icon(Icons.note_add, size: 18),
                  label: const Text('Gerar Faturas'),
                ),
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
                    ],
                    emptyMessage: 'Nenhuma fatura emitida.',
                    errorMessage: 'Erro ao carregar faturas',
                    onRetry: _load,
                    onPageChanged: _goToPage,
                    pageSize: _pageSize,
                    onPageSizeChanged: _changePageSize,
                    rowBuilder: (context, invoice) => _InvoiceRow(invoice: invoice),
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

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});

  final Invoice invoice;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        ],
      ),
    );
  }
}
