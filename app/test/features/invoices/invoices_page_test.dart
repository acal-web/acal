import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/light_theme.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/presentation/invoices_page.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);

final _connection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  letter: 'A',
  customer: const Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', voter: false),
  address: const Address(id: 'addr-1', kind: 'Avenida', name: 'Fernando Daltro'),
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
  connectionId: 'conn-1',
  referenceDate: DateTime(2026, 8, 1),
  dueDate: DateTime(2026, 8, 10),
  amount: 20.0,
  connection: _connection,
);

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({required this.invoices});

  final List<Invoice> invoices;
  int? lastYear;
  int? lastMonth;

  @override
  Future<PagedResult<Invoice>> findAll({int page = 0, int size = 10, int? year, int? month}) async {
    lastYear = year;
    lastMonth = month;
    return PagedResult(data: invoices, pagination: _pagination);
  }
}

GoRouter _router(InvoiceService invoiceService) => GoRouter(
      initialLocation: '/invoices',
      routes: [
        GoRoute(
          path: '/invoices',
          builder: (_, _) => InvoicesPage(invoiceService: invoiceService),
        ),
        GoRoute(
          path: '/invoices/generate',
          builder: (_, _) => const Scaffold(body: Text('Gerar Faturas Page')),
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, InvoiceService invoiceService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp.router(theme: lightTheme, routerConfig: _router(invoiceService)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists invoices with connection, due date and amount', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12A'), findsOneWidget);
    expect(find.text('08/2026'), findsOneWidget);
    expect(find.text('10/08/2026'), findsOneWidget);
    expect(find.text(formatBRL(20.0)), findsOneWidget);
  });

  testWidgets('shows a placeholder dash when the connection is missing', (tester) async {
    final invoiceWithoutConnection = Invoice(
      id: 'inv-2',
      connectionId: 'conn-2',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      amount: 20.0,
    );
    final service = _FakeInvoiceService(invoices: [invoiceWithoutConnection]);
    await _pump(tester, service);

    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('filtering by period passes year and month to the service', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    expect(service.lastYear, isNull);
    expect(service.lastMonth, isNull);

    await tester.tap(find.text('Todos os períodos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(service.lastYear, DateTime.now().year);
    expect(service.lastMonth, DateTime.now().month);
  });

  testWidgets('Gerar Faturas navigates to the generate page', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    await tester.tap(find.text('Gerar Faturas'));
    await tester.pumpAndSettle();

    expect(find.text('Gerar Faturas Page'), findsOneWidget);
  });
}
