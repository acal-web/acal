import 'package:acalapp/features/invoices/widget/invoice/invoice_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the association header with the provided icon', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: InvoiceTitle(icon: Icon(Icons.water_drop), child: Text('child')),
      ),
    ));

    expect(find.byIcon(Icons.water_drop), findsOneWidget);
    expect(find.textContaining('ACAL - Associação Comunitária e Assistencial de Lages'), findsOneWidget);
    expect(find.textContaining('ECONOMIZAR ÁGUA É UM DEVER DE TODO SER HUMANO.'), findsOneWidget);
  });
}
