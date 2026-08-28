import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/date_range_filter_button.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/stat_card.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Lists paid invoices (money received) within a date range, with quick
/// shortcuts for "today" and "this week" — driven off `GET /invoices/cashbox`.
class CashboxPage extends StatefulWidget {
  const CashboxPage({super.key, this.invoiceService});

  final InvoiceService? invoiceService;

  @override
  State<CashboxPage> createState() => _CashboxPageState();
}

class _CashboxPageState extends State<CashboxPage> {
  late final InvoiceService _service;
  DateTimeRange? _range;
  int _page = 0;
  int _pageSize = 10;
  late Future<({PagedResult<Invoice> page, double totalAmount})> _future;
  late Future<PagedResult<Invoice>> _pageFuture;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _range = _today();
    _load();
  }

  DateTimeRange _today() {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: day, end: day);
  }

  DateTimeRange _thisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return DateTimeRange(start: monday, end: monday.add(const Duration(days: 6)));
  }

  void _load() {
    _future = _service.cashbox(
      page: _page,
      size: _pageSize,
      startDate: _range?.start,
      endDate: _range?.end,
    );
    _pageFuture = _future.then((r) => r.page);
  }

  void _reload() => setState(_load);

  void _setRange(DateTimeRange? range) => setState(() {
    _range = range;
    _page = 0;
    _load();
  });

  void _changePage(int page) => setState(() {
    _page = page;
    _load();
  });

  void _changePageSize(int size) => setState(() {
    _pageSize = size;
    _page = 0;
    _load();
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(subtitle: 'Faturas pagas, com o valor recebido no período.'),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text('Período', style: Theme.of(context).textTheme.labelLarge),
                  DateRangeFilterButton(range: _range, onChanged: _setRange),
                  FButton(
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => _setRange(_today()),
                    child: const Text('Hoje'),
                  ),
                  FButton(
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => _setRange(_thisWeek()),
                    child: const Text('Essa semana'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FutureBuilder<({PagedResult<Invoice> page, double totalAmount})>(
                future: _future,
                builder: (context, snapshot) => SizedBox(
                  width: 240,
                  child: StatCard(
                    label: 'Valor recebido no período',
                    value: snapshot.hasData ? formatBRL(snapshot.data!.totalAmount) : '...',
                    icon: Icons.payments_outlined,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PagedListView<Invoice>(
                future: _pageFuture,
                columns: const [
                  DataTableColumn('SÓCIO', flex: 3),
                  DataTableColumn('LIGAÇÃO', flex: 3),
                  DataTableColumn('REFERÊNCIA', flex: 2),
                  DataTableColumn('PAGO EM', flex: 2),
                  DataTableColumn('VALOR', width: 120),
                ],
                rowBuilder: (context, invoice) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    spacing: columnSpacing,
                    children: [
                      Expanded(flex: 3, child: Text(invoice.connection?.customer?.name ?? '-')),
                      Expanded(
                        flex: 3,
                        child: Text(
                          invoice.connection == null
                              ? '-'
                              : '${invoice.connection!.address?.name ?? ''}, ${invoice.connection!.number}',
                        ),
                      ),
                      Expanded(flex: 2, child: Text(formatMonthReference(invoice.referenceDate))),
                      Expanded(flex: 2, child: Text(_formatDate(invoice.paidAt))),
                      SizedBox(width: 120, child: Text(formatBRL(invoice.amount))),
                    ],
                  ),
                ),
                emptyMessage: 'Nenhuma fatura paga encontrada no período.',
                errorMessage: 'Erro ao carregar o caixa.',
                onRetry: _reload,
                pageSize: _pageSize,
                onPageChanged: _changePage,
                onPageSizeChanged: _changePageSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
