import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_water_quality_section.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Invoice _invoiceWith(List<QualityAnalysis>? analyses) => Invoice(
      connectionId: 'conn-1',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      membershipValue: 5,
      waterValue: 15,
      qualityAnalyses: analyses,
    );

void main() {
  testWidgets('shows a message when there is no quality analysis data', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceWaterQualitySection(invoice: _invoiceWith(null)))));

    expect(find.text('Sem dados de análise de qualidade disponíveis'), findsOneWidget);
  });

  testWidgets('lists each analysis with its required/analyzed/compliant values', (tester) async {
    final analyses = [
      QualityAnalysis(referenceDate: DateTime(2026, 8, 1), paramName: 'Turbidez', required: 5, analyzed: 3, compliant: 3),
      QualityAnalysis(referenceDate: DateTime(2026, 8, 1), paramName: 'Cloro Residual', required: 2, analyzed: 1, compliant: 1),
    ];

    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceWaterQualitySection(invoice: _invoiceWith(analyses)))));

    expect(find.text('Turbidez'), findsOneWidget);
    expect(find.text('Cloro Residual'), findsOneWidget);
    expect(find.text('Sem dados de análise de qualidade disponíveis'), findsNothing);
  });
}
