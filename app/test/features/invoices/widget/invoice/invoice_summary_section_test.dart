import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_summary_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

void main() {
  testWidgets('shows reference month, dates and the itemized total', (tester) async {
    final invoice = Invoice(
      connectionId: 'conn-1',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      membershipValue: 5,
      waterValue: 15,
      waterConsumedValue: 3,
    );

    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceSummarySection(invoice: invoice))));

    expect(find.text('agosto, 2026'), findsOneWidget);
    expect(find.text('01 ago. 2026'), findsOneWidget);
    expect(find.text('10 ago. 2026'), findsOneWidget);
    expect(find.text(_currency.format(5)), findsOneWidget);
    expect(find.text(_currency.format(15)), findsOneWidget);
    expect(find.text(_currency.format(3)), findsOneWidget);
    expect(find.text(_currency.format(23)), findsOneWidget);
  });

  testWidgets('treats a missing water-consumed value as zero in the total', (tester) async {
    final invoice = Invoice(connectionId: 'conn-1', referenceDate: DateTime(2026, 8, 1), dueDate: DateTime(2026, 8, 10), membershipValue: 5, waterValue: 15);

    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceSummarySection(invoice: invoice))));

    expect(find.text(_currency.format(20)), findsOneWidget);
  });
}
