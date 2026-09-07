// See test/integration/categories_flow_test.dart for what this tier covers
// and why it's plain flutter_test rather than package:integration_test.
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/presentation/customer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _FakeCustomerService extends CustomerService {
  final List<Customer> _customers = [];
  int _nextId = 1;

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
    final filtered = _customers.where((c) => c.active == (active ?? true)).toList();
    return PagedResult(
      data: filtered,
      pagination: Pagination(number: 0, totalPages: 1, totalElements: filtered.length, size: size, first: true, last: true),
    );
  }

  @override
  Future<Customer> create(Customer customer) async {
    final saved = Customer(id: 'cust-${_nextId++}', name: customer.name, document: customer.document, voter: customer.voter);
    _customers.add(saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    final index = _customers.indexWhere((c) => c.id == id);
    _customers[index] = Customer(id: _customers[index].id, name: _customers[index].name, document: _customers[index].document, voter: _customers[index].voter, active: false);
  }

  @override
  Future<Customer> restore(String id) async {
    final index = _customers.indexWhere((c) => c.id == id);
    _customers[index] = Customer(id: _customers[index].id, name: _customers[index].name, document: _customers[index].document, voter: _customers[index].voter, active: true);
    return _customers[index];
  }
}

Future<void> _pump(WidgetTester tester, CustomerService service) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CustomersPage(customerService: service),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates a customer through the modal and it appears in the list', (tester) async {
    final service = _FakeCustomerService();
    // The wide layout only draws its header (and with it the "Adicionar"
    // button) once the table has at least one row — CustomersPage has no
    // stable per-row Key (unlike categories/addresses), so this test keeps a
    // single row throughout instead of also exercising delete on an ambiguous
    // one; delete is already covered at the widget-test level.
    await service.create(const Customer(name: 'Ancora', document: '00000000000', voter: false));
    await _pump(tester, service);

    expect(find.text('Ancora'), findsOneWidget);

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Fulano de Tal');
    await tester.enterText(find.byType(TextField).at(1), '123.456.789-09');
    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Sócio criado com sucesso.'), findsOneWidget);
    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(service._customers.map((c) => c.document), contains('12345678909'));
  });
}
