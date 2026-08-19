import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_title.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_customer_section.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_payment_section.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_summary_section.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_water_quality_section.dart';
import 'package:flutter/material.dart';

class InvoiceDetailsCard extends StatelessWidget {
  const InvoiceDetailsCard({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: cs.outlineVariant, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1 - Title
                InvoiceTitle(
                  icon: Icon(
                    Icons.business,
                    size: 80,
                    color: cs.primary,
                  ),
                ),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: InvoiceCustomerSection(invoice: invoice),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: InvoicePaymentSection(invoice: invoice),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: InvoiceSummarySection(invoice: invoice),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                InvoiceWaterQualitySection(invoice: invoice),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
