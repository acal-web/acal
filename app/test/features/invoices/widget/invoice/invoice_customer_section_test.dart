import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/domain/water_meter.dart';
import 'package:acalapp/features/invoices/widget/invoice/invoice_customer_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _connection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  legacyId: 4321,
  customer: Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', customerCode: '004321', voter: false),
  address: Address(id: 'addr-1', name: 'Avenida Fernando Daltro'),
  category: Category(id: 'cat-1', name: 'Residente', group: 'efetivo', hasWaterMeter: true, waterPrice: 15, membershipPrice: 5),
);

final _waterMeter = WaterMeter(invoiceId: 'inv-1', initialReading: 100, finalReading: 150, measuredAt: DateTime(2026, 8, 1));

final _invoice = Invoice(
  connectionId: 'conn-1',
  referenceDate: DateTime(2026, 8, 1),
  dueDate: DateTime(2026, 8, 10),
  membershipValue: 5,
  waterValue: 15,
  connection: _connection,
  waterMeter: _waterMeter,
);

void main() {
  testWidgets('shows the location, customer with associate number, category and meter readings', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceCustomerSection(invoice: _invoice))));

    expect(find.text('Endereço'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12'), findsOneWidget);
    expect(find.text('Fulano de Tal, 4321'), findsOneWidget);
    expect(find.text('004321'), findsOneWidget);
    expect(find.text('Residente'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('shows the customer name alone when the connection has no associate number', (tester) async {
    final invoice = Invoice(
      connectionId: 'conn-1',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      membershipValue: 5,
      waterValue: 15,
      connection: const Connection(
        id: 'conn-1',
        customerId: 'cust-1',
        addressId: 'addr-1',
        categoryId: 'cat-1',
        number: 12,
        customer: Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', customerCode: '004321', voter: false),
        address: Address(id: 'addr-1', name: 'Avenida Fernando Daltro'),
        category: Category(id: 'cat-1', name: 'Residente', group: 'efetivo', hasWaterMeter: true, waterPrice: 15, membershipPrice: 5),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceCustomerSection(invoice: invoice))));

    expect(find.text('Fulano de Tal'), findsOneWidget);
  });

  testWidgets('falls back to dashes when there is no connection or meter', (tester) async {
    final invoice = Invoice(connectionId: 'conn-1', referenceDate: DateTime(2026, 8, 1), dueDate: DateTime(2026, 8, 10), membershipValue: 5, waterValue: 15);
    await tester.pumpWidget(MaterialApp(home: Material(child: InvoiceCustomerSection(invoice: invoice))));

    expect(find.text('—'), findsWidgets);
  });
}
