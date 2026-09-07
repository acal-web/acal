import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_payment_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the boleto number and paid-at date', (tester) async {
    final invoice = Invoice(
      number: '2026.08.000001',
      connectionId: 'conn-1',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      membershipValue: 5,
      waterValue: 15,
      paidAt: DateTime(2026, 8, 3),
    );

    await tester.pumpWidget(MaterialApp(home: Material(child: InvoicePaymentSection(invoice: invoice))));

    expect(find.text('2026.08.000001'), findsOneWidget);
    expect(find.text('Pago em'), findsOneWidget);
    expect(find.text('03 ago. 2026'), findsOneWidget);
  });

  testWidgets('shows no paid-at box when the invoice is still open', (tester) async {
    final invoice = Invoice(connectionId: 'conn-1', referenceDate: DateTime(2026, 8, 1), dueDate: DateTime(2026, 8, 10), membershipValue: 5, waterValue: 15);

    await tester.pumpWidget(MaterialApp(home: Material(child: InvoicePaymentSection(invoice: invoice))));

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Pago em'), findsNothing);
  });
}
