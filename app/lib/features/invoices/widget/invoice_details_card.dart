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

                const SizedBox(height: 32),

                CustomPaint(
                  painter: DashedLinePainter(color: cs.outlineVariant),
                  size: Size(double.infinity, 1),
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
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 5,
    this.dashSpace = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}
