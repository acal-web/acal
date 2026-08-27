import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:acalapp/features/customer_portal/data/customer_invoice_service.dart';
import 'package:acalapp/features/customer_portal/presentation/current_customer_scope.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';

class MyInvoicesPage extends StatefulWidget {
  const MyInvoicesPage({super.key, CustomerInvoiceService? service}) : _service = service;

  final CustomerInvoiceService? _service;

  @override
  State<MyInvoicesPage> createState() => _MyInvoicesPageState();
}

class _MyInvoicesPageState extends State<MyInvoicesPage> {
  late final CustomerInvoiceService _service;
  final _scrollController = ScrollController();
  final List<Invoice> _invoices = [];

  static const _pageSize = 20;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? CustomerInvoiceService();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.findAll(page: _currentPage, size: _pageSize);

      if (mounted) {
        setState(() {
          _invoices.addAll(result.data);
          _hasMorePages = result.pagination.nextPage != null;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Não foi possível carregar suas faturas.';
        });
      }
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final customer = CurrentCustomerScope.of(context).customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer != null ? 'Faturas de ${customer.name}' : 'Minhas Faturas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => CurrentCustomerScope.of(context).logout(),
          ),
        ],
      ),
      body: _errorMessage != null && _invoices.isEmpty
          ? _buildErrorView(theme, cs)
          : _invoices.isEmpty && !_isLoading
              ? Center(
                  child: Text(
                    'Nenhuma fatura em aberto.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.outline),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _invoices.length + (_isLoading ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == _invoices.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return _InvoiceCard(invoice: _invoices[index], service: _service, formatDate: _formatDate);
                  },
                ),
    );
  }

  Widget _buildErrorView(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: cs.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNextPage,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatefulWidget {
  const _InvoiceCard({required this.invoice, required this.service, required this.formatDate});

  final Invoice invoice;
  final CustomerInvoiceService service;
  final String Function(DateTime) formatDate;

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _loadingPdf = false;

  Future<void> _viewPdf() async {
    final id = widget.invoice.id;
    if (id == null) return;

    setState(() => _loadingPdf = true);
    try {
      await Printing.layoutPdf(onLayout: (_) => widget.service.pdf(id));
    } catch (_) {
      // Ignore — the print/preview dialog surfaces its own errors.
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final invoice = widget.invoice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Referência ${formatMonthReference(invoice.referenceDate)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vencimento ${widget.formatDate(invoice.dueDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(formatBRL(invoice.amount), style: theme.textTheme.titleMedium),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pendente',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: _loadingPdf
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Ver fatura',
              onPressed: _loadingPdf ? null : _viewPdf,
            ),
          ],
        ),
      ),
    );
  }
}
