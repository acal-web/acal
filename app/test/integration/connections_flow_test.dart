// See test/integration/categories_flow_test.dart for what this tier covers
// and why it's plain flutter_test rather than package:integration_test.
//
// The create-via-modal flow isn't exercised here: ConnectionFormPage's
// AddressSelectField/CustomerSelectField don't render reliably in a test
// overlay (see the `skip: true` cases already documented in
// test/features/connections/widget/connection_form_page_test.dart). This
// instead covers the filter bar and the list working together against a
// fake service — status changes and clearing actually change what's fetched
// and shown.
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/domain/connection_filter.dart';
import 'package:acalapp/features/connections/presentation/connections_page.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 0, size: 10, first: true, last: true);

class _FakeCustomerService extends CustomerService {
  @override
  Future<PagedResult<Customer>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    String? document,
    String? sort,
    bool sortAscending = true,
    bool? active = true,
  }) async =>
      const PagedResult(data: [], pagination: _pagination);
}

class _FakeAddressService extends AddressService {
  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async =>
      const PagedResult(data: [], pagination: _pagination);
}

class _FakeCategoryService extends CategoryService {
  @override
  Future<PagedResult<Category>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async =>
      const PagedResult(data: [], pagination: _pagination);
}

const _activeConnection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  active: true,
  customer: Customer(id: 'cust-1', name: 'Fulano Ativo', document: '11111111111', voter: false),
  address: Address(id: 'addr-1', name: 'Rua A'),
  category: Category(id: 'cat-1', name: 'Residente', group: 'efetivo', hasWaterMeter: true, waterPrice: 15, membershipPrice: 5),
);

const _inactiveConnection = Connection(
  id: 'conn-2',
  customerId: 'cust-2',
  addressId: 'addr-2',
  categoryId: 'cat-1',
  number: 34,
  active: false,
  customer: Customer(id: 'cust-2', name: 'Beltrano Inativo', document: '22222222222', voter: false),
  address: Address(id: 'addr-2', name: 'Rua B'),
  category: Category(id: 'cat-1', name: 'Residente', group: 'efetivo', hasWaterMeter: true, waterPrice: 15, membershipPrice: 5),
);

class _FakeConnectionService extends ConnectionService {
  final _connections = [_activeConnection, _inactiveConnection];

  @override
  Future<PagedResult<Connection>> findAll({
    int page = 0,
    int size = 10,
    ConnectionFilter filter = const ConnectionFilter(),
    String? sortBy,
    String? sortDirection,
  }) async {
    final filtered = switch (filter.status) {
      'inactive' => _connections.where((c) => !c.active).toList(),
      'all' => _connections,
      _ => _connections.where((c) => c.active).toList(),
    };
    return PagedResult(
      data: filtered,
      pagination: Pagination(number: 0, totalPages: 1, totalElements: filtered.length, size: size, first: true, last: true),
    );
  }
}

Future<void> _pump(WidgetTester tester, ConnectionService service) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: ConnectionsPage(
      connectionService: service,
      customerService: _FakeCustomerService(),
      addressService: _FakeAddressService(),
      categoryService: _FakeCategoryService(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the status filter round-trips through the fake service and updates the list', (tester) async {
    await _pump(tester, _FakeConnectionService());

    expect(find.text('Fulano Ativo'), findsOneWidget);
    expect(find.text('Beltrano Inativo'), findsNothing);

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(
      find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_BasicSelect<_ConnectionStatus>')),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inativos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Beltrano Inativo'), findsOneWidget);
    expect(find.text('Fulano Ativo'), findsNothing);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(find.text('Fulano Ativo'), findsOneWidget);
    expect(find.text('Beltrano Inativo'), findsNothing);
  });
}
