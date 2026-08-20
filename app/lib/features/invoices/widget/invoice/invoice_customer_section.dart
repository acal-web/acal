import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/domain/water_meter.dart';
import 'package:flutter/material.dart';

class InvoiceCustomerSection extends StatelessWidget {
  const InvoiceCustomerSection({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final connection = invoice.connection;
    final cs = Theme.of(context).colorScheme;

    final waterMeter = invoice.waterMeter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _buildAssociatedNumberBox(connection?.legacyId?.toString() ?? '—', cs),
        const SizedBox(height: 16),
        _buildInfoRow('Sócio', connection?.customer?.name ?? '—'),
        _buildInfoRow('Endereço', connection?.fullLocation ?? '—'),
        _buildInfoRow('Categoria', connection?.category?.name ?? '—'),
        const SizedBox(height: 16),
        Expanded(
          child: _buildMeterBox(waterMeter, cs),
        ),
      ],
    );
  }

  Widget _buildAssociatedNumberBox(String value, ColorScheme cs) {
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
            'Nº de Associado',
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterBox(WaterMeter? waterMeter, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildMeterColumn(
              'Leitura anterior:',
              waterMeter?.initialReading.toStringAsFixed(0) ?? '—',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMeterColumn(
              'Leitura atual:',
              waterMeter?.finalReading.toStringAsFixed(0) ?? '—',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildMeterColumn(
              'Consumo:',
              waterMeter?.realConsumption.toStringAsFixed(0) ?? '—',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
