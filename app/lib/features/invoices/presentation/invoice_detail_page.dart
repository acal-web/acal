import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice_details_card.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:printing/printing.dart';

class InvoiceDetailPage extends StatefulWidget {
  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
    this.invoiceService,
  });

  final String invoiceId;
  final InvoiceService? invoiceService;

  @override
  State<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends State<InvoiceDetailPage> {
  late final InvoiceService _service;
  late Future<Invoice> _future;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _future = _service.getById(widget.invoiceId);
  }

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _service.pdf(widget.invoiceId),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar PDF')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Fatura'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: FButton(
              variant: FButtonVariant.ghost,
              mainAxisSize: MainAxisSize.min,
              onPress: _printing ? null : _print,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.print_outlined, size: 18),
                  if (_printing)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: FCircularProgress(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Invoice>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: FCircularProgress());
          }
          if (snapshot.hasError) {
            return AsyncErrorView(
              message: 'Erro ao carregar fatura',
              onRetry: () => setState(() => _future = Future.error('Not implemented')),
            );
          }

          final invoice = snapshot.data!;
          return SingleChildScrollView(
            child: InvoiceDetailsCard(invoice: invoice),
          );
        },
      ),
    );
  }
}
