import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InvoiceSummarySection extends StatelessWidget {
  const InvoiceSummarySection({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    final monthFormat = DateFormat('MMMM, yyyy', 'pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _buildReferenceMonthBox(monthFormat.format(invoice.referenceDate), cs),
        const SizedBox(height: 16),
        _buildInfoRow('Data de Emissão', DateFormat('dd MMM yyyy', 'pt_BR').format(invoice.referenceDate)),
        _buildInfoRow('Vencimento', DateFormat('dd MMM yyyy', 'pt_BR').format(invoice.dueDate)),
        const SizedBox(height: 8),
        _buildSummaryRow('Taxa mínima', invoice.membershipValue, currencyFormat),
        _buildSummaryRow('Valor Excesso', 0.0, currencyFormat),
        _buildSummaryRow('Outras Taxas', 0.0, currencyFormat),
        _buildSummaryRow('Taxa de Sócio', invoice.membershipValue, currencyFormat),
        const SizedBox(height: 12),
        _buildTotalBox(invoice.amount, currencyFormat, cs),
      ],
    );
  }

  Widget _buildReferenceMonthBox(String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Conta referente:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    NumberFormat currencyFormat, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBox(double value, NumberFormat currencyFormat, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Valor total',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
