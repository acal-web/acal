import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/presentation/customer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _customer = Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', voter: true);
const _inactiveCustomer = Customer(
  id: 'cust-2',
  name: 'Beltrano da Silva',
  document: '98765432100',
  voter: false,
  active: false,
);

class _FakeCustomerService extends CustomerService {
  _FakeCustomerService({List<Customer>? customers}) : customers = customers ?? [_customer];

  List<Customer> customers;
  String? deletedId;
  String? restoredId;

  @override
  Future<PagedResult<Customer>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    String? document,
    String? sort,
    bool sortAscending = true,
    bool? active = true,
  }) async {
    return PagedResult(
      data: customers,
      pagination: Pagination(number: 0, totalPages: 1, totalElements: customers.length, size: size, first: true, last: true),
    );
  }

  @override
  Future<void> delete(String id) async {
    deletedId = id;
    customers = customers.where((c) => c.id != id).toList();
  }

  @override
  Future<Customer> restore(String id) async {
    restoredId = id;
    return _customer;
  }
}

Future<void> _pump(WidgetTester tester, CustomerService customerService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CustomersPage(customerService: customerService),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists customers with document and voter status', (tester) async {
    await _pump(tester, _FakeCustomerService());

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no customers', (tester) async {
    await _pump(tester, _FakeCustomerService(customers: []));

    expect(find.text('Nenhum sócio cadastrado.'), findsOneWidget);
  });

  testWidgets('deleting a row confirms and removes it from the list', (tester) async {
    final service = _FakeCustomerService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm_button')));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'cust-1');
    expect(find.text('Nenhum sócio cadastrado.'), findsOneWidget);
  });

  testWidgets('reactivating an inactive customer calls restore and reloads', (tester) async {
    final service = _FakeCustomerService(customers: [_inactiveCustomer]);
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_reactivate')));
    await tester.pumpAndSettle();

    expect(service.restoredId, 'cust-2');
  });
}
