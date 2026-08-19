import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:flutter/material.dart';

class InvoiceWaterQualitySection extends StatelessWidget {
  const InvoiceWaterQualitySection({
    super.key,
    required this.invoice,
  });

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final analyses = invoice.qualityAnalyses ?? [];

    if (analyses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PADRÃO DA PORTARIA MS 2914/2011',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Sem dados de análise de qualidade disponíveis',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PADRÃO DA PORTARIA MS 2914/2011',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: cs.outlineVariant, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildTableHeaderRow(cs),
              _buildTableHeader(cs),
              ...analyses.map((analysis) => _buildTableRow(analysis, cs)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildTableHeaderRow(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Text(
          'Decreto Federal nº 5.440/2005',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            flex: 40,
            child: _buildTableCell('Parâmetros', cs, isHeader: true),
          ),
          Expanded(
            flex: 20,
            child: _buildTableCell('Exigidas', cs, isHeader: true),
          ),
          Expanded(
            flex: 20,
            child: _buildTableCell('Analisadas', cs, isHeader: true),
          ),
          Expanded(
            flex: 20,
            child: _buildTableCell('Conformidade', cs, isHeader: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(QualityAnalysis analysis, ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          flex: 40,
          child: _buildTableCell(analysis.paramName, cs),
        ),
        Expanded(
          flex: 20,
          child: _buildTableCell(analysis.required.toString(), cs),
        ),
        Expanded(
          flex: 20,
          child: _buildTableCell(analysis.analyzed.toString(), cs),
        ),
        Expanded(
          flex: 20,
          child: _buildTableCell(analysis.compliant.toString(), cs),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, ColorScheme cs, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: cs.outlineVariant, width: 0.5),
          bottom: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Parâmetros de Qualidade da Água',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'Coliformes Totais',
          'Indicador que mensura contaminação bacteriológica, do tipo: bacilos gram-negativos, aeróbios ou anaeróbios facultativos não esporogênicos, oxidase-negativos.',
        ),
        _buildLegendItem(
          'E.coli',
          'Indicador que mensura contaminação bacteriológica de origem fecal.',
        ),
        _buildLegendItem(
          'Cloro Residual',
          'Indicador de Poder Desinfetante oriundo do Cloro (Agente de Desinfecção).',
        ),
        _buildLegendItem(
          'Turbidez',
          'Indicador do espalhamento de luz produzido pela presença de partículas em suspensão ou coloidais.',
        ),
        _buildLegendItem(
          'Cor Aparente',
          'Indicador que mensura a cor em amostras com turbidez.',
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
