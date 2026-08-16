import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/presentation/invoice_detail_page.dart';
import 'package:acalapp/features/invoices/widget/invoice_filter_bar.dart';
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
  final _scrollController = ScrollController();
  final List<Invoice> _allInvoices = [];

  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  bool _printingAll = false;
  MonthYear? _period;
  String? _customerId;
  String? _addressId;
  String? _status;
  String? _errorMessage;
  String _sortBy = 'reference_date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      final result = await _service.findAll(
        page: _currentPage,
        size: _pageSize,
        year: _period?.year,
        month: _period?.month,
        customerId: _customerId,
        addressId: _addressId,
        status: _status,
        sortBy: _sortBy,
        sortAscending: _sortAscending,
      );

      if (mounted) {
        setState(() {
          _allInvoices.addAll(result.data);
          _totalCount = result.pagination.totalElements;
          _hasMorePages = result.pagination.nextPage != null;
          _currentPage++;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar faturas';
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

  void _search({
    MonthYear? period,
    String? customerId,
    String? addressId,
    String? status,
  }) async {
    _period = period;
    _customerId = customerId;
    _addressId = addressId;
    _status = status;
    await _loadFirstPage();
  }

  void _sort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = false;
      }
    });
    _loadFirstPage();
  }

  Future<void> _reloadData() async {
    await _loadFirstPage();
  }

  Future<void> _printAll() async {
    if (_allInvoices.length > 3000) {
      if (mounted) {
        AppToast.error(context, 'Máximo de 3000 faturas por impressão. Filtre os resultados.');
      }
      return;
    }

    setState(() => _printingAll = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _service.printFiltered(
          year: _period?.year,
          month: _period?.month,
          customerId: _customerId,
          addressId: _addressId,
          status: _status,
        ),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao gerar o relatório.');
    } finally {
      if (mounted) setState(() => _printingAll = false);
    }
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
            InvoiceFilterBar(onSearch: _search),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FButton(
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                onPress: _allInvoices.isEmpty || _printingAll || _allInvoices.length > 3000 ? null : _printAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.print_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _printingAll
                          ? 'Gerando...'
                          : _allInvoices.length > 3000
                              ? 'Máximo 3000 itens'
                              : 'Imprimir Filtrados',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allInvoices.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma fatura emitida.'))
                      : _buildTableWithInfiniteScroll(),
            ),
            if (_allInvoices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mostrando ${_allInvoices.length} de $_totalCount registros',
                  style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildTableWithInfiniteScroll() {
    return Column(
      children: [
        _TableHeader(
          sortBy: _sortBy,
          sortAscending: _sortAscending,
          onSort: _sort,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _allInvoices.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allInvoices.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final invoice = _allInvoices[index];
              final isEven = index.isEven;

              return Column(
                children: [
                  _InvoiceRow(
                    invoice: invoice,
                    service: _service,
                    onChanged: _reloadData,
                    isEven: isEven,
                  ),
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

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.sortBy,
    required this.sortAscending,
    required this.onSort,
  });

  final String sortBy;
  final bool sortAscending;
  final Function(String) onSort;

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
          SizedBox(
            width: 110,
            child: _SortableHeader(
              label: 'Número',
              sortBy: 'number',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSort,
              style: headerStyle,
            ),
          ),
          SizedBox(
            width: 90,
            child: _SortableHeader(
              label: 'Referência',
              sortBy: 'reference_date',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSort,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: _SortableHeader(
              label: 'Sócio',
              sortBy: 'customer_name',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSort,
              style: headerStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text('Ligação', style: headerStyle),
          ),
          SizedBox(
            width: 110,
            child: _SortableHeader(
              label: 'Vencimento',
              sortBy: 'due_date',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSort,
              style: headerStyle,
            ),
          ),
          SizedBox(
            width: 120,
            child: _SortableHeader(
              label: 'Valor',
              sortBy: 'amount',
              currentSort: sortBy,
              ascending: sortAscending,
              onSort: onSort,
              style: headerStyle,
            ),
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

  Future<void> _viewDetails(String invoiceId) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceDetailPage(invoiceId: invoiceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final invoice = widget.invoice;
    final connection = invoice.connection;
    final daysOverdue = DateTime.now().difference(invoice.dueDate).inDays;
    final isOverdue = !invoice.isPaid && daysOverdue > 59;

    final backgroundColor = invoice.isPaid
        ? Colors.green.withValues(alpha: 0.15)
        : isOverdue
            ? Colors.red.withValues(alpha: 0.15)
            : widget.isEven
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainer.withValues(alpha: 0.4);

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                invoice.number ?? '—',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 80,
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
                  PopupMenuButton<String>(
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'view',
                        onTap: invoice.id != null
                            ? () => Future.microtask(() => _viewDetails(invoice.id!))
                            : null,
                        child: const Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 18),
                            SizedBox(width: 12),
                            Text('Visualizar'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'download',
                        child: const Row(
                          children: [
                            Icon(Icons.picture_as_pdf_outlined, size: 18),
                            SizedBox(width: 12),
                            Text('Imprimir Boleto'),
                          ],
                        ),
                        onTap: () => Future.microtask(_downloadPdf),
                      ),
                      if (!invoice.isPaid)
                        PopupMenuItem<String>(
                          value: 'mark_paid',
                          child: const Row(
                            children: [
                              Icon(Icons.attach_money, size: 18),
                              SizedBox(width: 12),
                              Text('Marcar como Paga'),
                            ],
                          ),
                          onTap: () => Future.microtask(_markPaid),
                        ),
                      if (invoice.isPaid)
                        PopupMenuItem<String>(
                          value: 'paid',
                          enabled: false,
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 12),
                              Text('Paga'),
                            ],
                          ),
                        ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (_marking)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(2),
                        child: FCircularProgress(),
                      ),
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

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.sortBy,
    required this.currentSort,
    required this.ascending,
    required this.onSort,
    required this.style,
  });

  final String label;
  final String sortBy;
  final String currentSort;
  final bool ascending;
  final Function(String) onSort;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isActive = currentSort == sortBy;
    final icon = !isActive
        ? Icons.unfold_more
        : ascending
            ? Icons.arrow_upward
            : Icons.arrow_downward;

    return GestureDetector(
      onTap: () => onSort(sortBy),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Flexible(
            child: Text(label, style: style),
          ),
          Icon(
            icon,
            size: 14,
            color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
        ],
      ),
    );
  }
}
