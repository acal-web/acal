import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/cashbox/presentation/cashbox_page.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);

final _connection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  letter: 'A',
  customer: const Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', voter: false),
  address: const Address(id: 'addr-1', name: 'Avenida Fernando Daltro'),
  category: const Category(
    id: 'cat-1',
    name: 'Residente',
    group: 'efetivo',
    hasWaterMeter: true,
    waterPrice: 15,
    membershipPrice: 5,
  ),
);

final _invoice = Invoice(
  id: 'inv-1',
  number: '2026.08.000001',
  connectionId: 'conn-1',
  referenceDate: DateTime(2026, 8, 1),
  dueDate: DateTime(2026, 8, 10),
  membershipValue: 15.0,
  waterValue: 5.0,
  paidAt: DateTime(2026, 8, 3),
  connection: _connection,
);

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({required this.invoices, this.totalAmount = 0});

  final List<Invoice> invoices;
  final double totalAmount;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  @override
  Future<({PagedResult<Invoice> page, double totalAmount})> cashbox({
    int page = 0,
    int size = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    lastStartDate = startDate;
    lastEndDate = endDate;
    return (page: PagedResult(data: invoices, pagination: _pagination), totalAmount: totalAmount);
  }
}

Future<void> _pump(WidgetTester tester, InvoiceService invoiceService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CashboxPage(invoiceService: invoiceService),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists paid invoices with the received total', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice], totalAmount: 20.0);
    await _pump(tester, service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12'), findsOneWidget);
    expect(find.text(formatBRL(20.0)), findsWidgets);
  });

  testWidgets('defaults the filter to today', (tester) async {
    final service = _FakeInvoiceService(invoices: []);
    await _pump(tester, service);

    final today = DateTime.now();
    final expected = DateTime(today.year, today.month, today.day);
    expect(service.lastStartDate, expected);
    expect(service.lastEndDate, expected);
  });

  testWidgets('"Essa semana" loads the current week range', (tester) async {
    final service = _FakeInvoiceService(invoices: []);
    await _pump(tester, service);

    await tester.tap(find.text('Essa semana'));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    final start = service.lastStartDate!;
    final end = service.lastEndDate!;
    expect(end.difference(start).inDays, 6);
    expect(start.weekday, DateTime.monday);
    expect(today.isBefore(start) || today.isAfter(end), isFalse);
  });

  testWidgets('shows an empty message when nothing was paid', (tester) async {
    final service = _FakeInvoiceService(invoices: []);
    await _pump(tester, service);

    expect(find.text('Nenhuma fatura paga encontrada no período.'), findsOneWidget);
  });
}
