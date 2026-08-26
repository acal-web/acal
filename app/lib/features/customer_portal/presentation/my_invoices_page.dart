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
  late Future<List<Invoice>> _invoicesFuture;

  @override
  void initState() {
    super.initState();
    _service = widget._service ?? CustomerInvoiceService();
    _invoicesFuture = _load();
  }

  Future<List<Invoice>> _load() async {
    final result = await _service.findAll(size: 100);
    return result.data;
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
      body: FutureBuilder<List<Invoice>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Não foi possível carregar suas faturas.',
                style: theme.textTheme.bodyMedium?.copyWith(color: cs.error),
              ),
            );
          }

          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) {
            return Center(
              child: Text('Nenhuma fatura encontrada.', style: theme.textTheme.bodyMedium?.copyWith(color: cs.outline)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _InvoiceCard(invoice: invoices[index], service: _service, formatDate: _formatDate),
          );
        },
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
                          color: (invoice.isPaid ? Colors.green : cs.error).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          invoice.isPaid ? 'Paga' : 'Pendente',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: invoice.isPaid ? Colors.green : cs.error,
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
