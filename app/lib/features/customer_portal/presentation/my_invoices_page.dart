import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_helpers.dart';
import 'package:acalapp/core/layout/topbar/topbar_fragments/topbar_user_menu.dart';
import 'package:acalapp/features/customer_portal/data/customer_invoice_service.dart';
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

    return Scaffold(
      appBar: const _PortalTopBar(),
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

/// Same toolbar as the staff [TopBar], minus the hamburger/[SideMenu] toggle
/// — the portal has no side menu to open, but keeps the same bell and user
/// avatar (with its logout action) for a consistent look.
class _PortalTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _PortalTopBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: SizedBox()),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: TopBarHelpers(),
                ),
                const TopBarUserMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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
    final connection = invoice.connection;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _loadingPdf ? null : _viewPdf,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      invoice.number ?? '—',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    formatMonthReference(invoice.referenceDate),
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(connection?.customer?.name ?? '—', style: theme.textTheme.bodyMedium),
              if (connection != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${connection.address?.name ?? '—'}, ${connection.number}${connection.letter ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vencimento:', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      Text(
                        widget.formatDate(invoice.dueDate),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Valor:', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          Text(
                            formatBRL(invoice.amount),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (_loadingPdf)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
