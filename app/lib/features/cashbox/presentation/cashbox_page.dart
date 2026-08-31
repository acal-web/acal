import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/collapsible_filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

const columnSpacing = 12.0;

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
  final _scrollController = ScrollController();
  final List<Invoice> _allInvoices = [];
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  double _totalAmount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  DateTimeRange? _range;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _scrollController.addListener(_onScroll);
    _range = _today();
    _syncControllers();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _startController.text = _range?.start != null ? _formatDate(_range!.start) : '';
    _endController.text = _range?.end != null ? _formatDate(_range!.end) : '';
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _range?.start ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 3, 12),
    );
    if (picked == null) return;

    final end = _range != null && picked.isAfter(_range!.end) ? picked : _range?.end ?? picked;
    _setRange(DateTimeRange(start: picked, end: end));
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _range?.end ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 3, 12),
    );
    if (picked == null) return;

    final start = _range != null && picked.isBefore(_range!.start) ? picked : _range?.start ?? picked;
    _setRange(DateTimeRange(start: start, end: picked));
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

  Future<void> _loadFirstPage() async {
    _allInvoices.clear();
    _currentPage = 0;
    _hasMorePages = true;
    _errorMessage = null;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMorePages) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _service.cashbox(
        page: _currentPage,
        size: _pageSize,
        startDate: _range?.start,
        endDate: _range?.end,
      );

      if (mounted) {
        setState(() {
          _allInvoices.addAll(result.page.data);
          _totalCount = result.page.pagination.totalElements;
          _totalAmount = result.totalAmount;
          _hasMorePages = result.page.pagination.nextPage != null;
          _currentPage++;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar o caixa';
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _setRange(DateTimeRange? range) {
    setState(() {
      _range = range;
      _syncControllers();
    });
    _loadFirstPage();
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
            CollapsibleFilterPanel(
              builder: (context, narrow) => Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 160,
                    child: FTextFormField(
                      control: FTextFieldControl.managed(controller: _startController),
                      readOnly: true,
                      label: const Text('Início'),
                      hint: 'Selecione a data',
                      suffixBuilder: (context, style, variants) => const Icon(Icons.calendar_today, size: 18),
                      onTap: _pickStart,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: FTextFormField(
                      control: FTextFieldControl.managed(controller: _endController),
                      readOnly: true,
                      label: const Text('Fim'),
                      hint: 'Selecione a data',
                      suffixBuilder: (context, style, variants) => const Icon(Icons.calendar_today, size: 18),
                      onTap: _pickEnd,
                    ),
                  ),
                  FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => _setRange(_today()),
                    child: const Text('Hoje'),
                  ),
                  FButton(
                    variant: FButtonVariant.outline,
                    size: FButtonSizeVariant.sm,
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => _setRange(_thisWeek()),
                    child: const Text('Essa semana'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allInvoices.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma fatura paga encontrada no período.'))
                      : _buildTableWithInfiniteScroll(narrow),
            ),
            if (_allInvoices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Mostrando ${_allInvoices.length} de $_totalCount registros',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Valor recebido no período: ${formatBRL(_totalAmount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFirstPage,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableWithInfiniteScroll(bool narrow) {
    return Column(
      children: [
        if (!narrow) ...[
          const _TableHeader(),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _allInvoices.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allInvoices.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final invoice = _allInvoices[index];
              final isEven = index.isEven;

              return narrow
                  ? _CashboxCard(invoice: invoice)
                  : Column(
                      children: [
                        _CashboxRow(invoice: invoice, isEven: isEven),
                        const Divider(height: 1),
                      ],
                    );
            },
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _connectionLabel(Invoice invoice) => invoice.connection == null
    ? '-'
    : '${invoice.connection!.address?.name ?? ''}, ${invoice.connection!.number}';

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        spacing: columnSpacing,
        children: [
          Expanded(flex: 3, child: Text('SÓCIO', style: headerStyle)),
          Expanded(flex: 3, child: Text('LIGAÇÃO', style: headerStyle)),
          Expanded(flex: 2, child: Text('REFERÊNCIA', style: headerStyle)),
          Expanded(flex: 2, child: Text('PAGO EM', style: headerStyle)),
          SizedBox(width: 120, child: Text('VALOR', style: headerStyle)),
        ],
      ),
    );
  }
}

class _CashboxRow extends StatelessWidget {
  const _CashboxRow({required this.invoice, this.isEven = false});

  final Invoice invoice;
  final bool isEven;

  static Color _backgroundColor(ColorScheme cs, bool isEven) => isEven
      ? cs.surfaceContainer.withValues(alpha: 0.2)
      : cs.surfaceContainer.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium;

    return ColoredBox(
      color: _backgroundColor(cs, isEven),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            Expanded(flex: 3, child: Text(invoice.connection?.customer?.name ?? '-', style: style)),
            Expanded(flex: 3, child: Text(_connectionLabel(invoice), style: style)),
            Expanded(flex: 2, child: Text(formatMonthReference(invoice.referenceDate), style: style)),
            Expanded(flex: 2, child: Text(_formatDate(invoice.paidAt), style: style)),
            SizedBox(width: 120, child: Text(formatBRL(invoice.amount), style: style)),
          ],
        ),
      ),
    );
  }
}

class _CashboxCard extends StatelessWidget {
  const _CashboxCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invoice.connection?.customer?.name ?? '-',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    formatBRL(invoice.amount),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _connectionLabel(invoice),
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatMonthReference(invoice.referenceDate)} · Pago em ${_formatDate(invoice.paidAt)}',
                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
