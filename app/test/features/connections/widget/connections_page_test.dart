import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/domain/connection_filter.dart';
import 'package:acalapp/features/connections/presentation/connections_page.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _customer = Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', voter: false);
const _address = Address(id: 'addr-1', name: 'Avenida Fernando Daltro');
const _category = Category(
  id: 'cat-1',
  name: 'Residente',
  group: 'efetivo',
  hasWaterMeter: true,
  waterPrice: 15,
  membershipPrice: 5,
);

const _connection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  letter: 'A',
  customer: _customer,
  address: _address,
  category: _category,
);

class _FakeConnectionService extends ConnectionService {
  _FakeConnectionService({List<Connection>? connections}) : connections = connections ?? [_connection];

  List<Connection> connections;
  String? deletedId;

  @override
  Future<PagedResult<Connection>> findAll({
    int page = 0,
    int size = 10,
    ConnectionFilter filter = const ConnectionFilter(),
    String? sortBy,
    String? sortDirection,
  }) async =>
      PagedResult(
        data: connections,
        pagination: Pagination(
          number: 0,
          totalPages: 1,
          totalElements: connections.length,
          size: size,
          first: true,
          last: true,
        ),
      );

  @override
  Future<void> delete(String id) async {
    deletedId = id;
    connections = connections.where((c) => c.id != id).toList();
  }
}

Future<void> _pump(WidgetTester tester, ConnectionService connectionService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: ConnectionsPage(connectionService: connectionService),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists connections with customer, location and category', (tester) async {
    await _pump(tester, _FakeConnectionService());

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12 A'), findsOneWidget);
    expect(find.text('Residente'), findsOneWidget);
    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no connections', (tester) async {
    await _pump(tester, _FakeConnectionService(connections: []));

    expect(find.text('Nenhuma ligação cadastrada.'), findsOneWidget);
  });

  testWidgets('deleting a row confirms and removes it from the list', (tester) async {
    final service = _FakeConnectionService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_delete')));
    await tester.pumpAndSettle();

    expect(find.text('Deseja excluir a ligação de "Fulano de Tal" em "Avenida Fernando Daltro"?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_confirm_button')));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'conn-1');
    expect(find.text('Nenhuma ligação cadastrada.'), findsOneWidget);
  });

  testWidgets('cancelling the delete confirmation keeps the row', (tester) async {
    final service = _FakeConnectionService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_cancel_button')));
    await tester.pumpAndSettle();

    expect(service.deletedId, isNull);
    expect(find.text('Fulano de Tal'), findsOneWidget);
  });
}
