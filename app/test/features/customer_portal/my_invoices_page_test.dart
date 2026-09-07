import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer_portal/data/customer_invoice_service.dart';
import 'package:acalapp/features/customer_portal/presentation/my_invoices_page.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _customer = Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', voter: false);
const _address = Address(id: 'addr-1', name: 'Avenida Fernando Daltro');
const _connection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  customer: _customer,
  address: _address,
);

final _invoice = Invoice(
  id: 'inv-1',
  number: '2026.08.000001',
  connectionId: 'conn-1',
  referenceDate: DateTime(2026, 8, 1),
  dueDate: DateTime(2026, 8, 10),
  membershipValue: 15.0,
  waterValue: 5.0,
  connection: _connection,
);

class _FakeCustomerInvoiceService extends CustomerInvoiceService {
  _FakeCustomerInvoiceService({List<Invoice>? invoices}) : invoices = invoices ?? [_invoice];

  List<Invoice> invoices;

  @override
  Future<PagedResult<Invoice>> findAll({int page = 0, int size = 10}) async => PagedResult(
        data: invoices,
        pagination: Pagination(number: 0, totalPages: 1, totalElements: invoices.length, size: size, first: true, last: true),
      );
}

Future<void> _pump(WidgetTester tester, CustomerInvoiceService service) async {
  final currentUser = CurrentUser();
  currentUser.setSession(
    AuthUser(id: 'cust-1', username: 'fulano', name: 'Fulano de Tal', role: UserRole.customer),
    'test-token',
  );

  await tester.pumpWidget(MaterialApp(
    home: CurrentUserScope(
      notifier: currentUser,
      child: MyInvoicesPage(service: service),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists the open invoices with due date and amount', (tester) async {
    await _pump(tester, _FakeCustomerInvoiceService());

    expect(find.text('2026.08.000001'), findsOneWidget);
    expect(find.text(formatBRL(20.0)), findsOneWidget);
    expect(find.text('10/08/2026'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no open invoices', (tester) async {
    await _pump(tester, _FakeCustomerInvoiceService(invoices: []));

    expect(find.text('Nenhuma fatura em aberto.'), findsOneWidget);
  });
}
