import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/widget/connection_filter_bar.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);
const _customer = Customer(id: 'cust1', name: 'Fulano de Tal', document: '12345678909', voter: true);
const _category = Category(id: 'cat1', name: 'Padrão', group: 'efetivo', hasWaterMeter: true, waterPrice: 12.5, membershipPrice: 30);

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
  }) async {
    final filtered = (name == null || name.isEmpty) ? const [_customer] : const [_customer];
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

class _FakeCategoryService extends CategoryService {
  @override
  Future<PagedResult<Category>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async {
    return const PagedResult(data: [_category], pagination: _pagination);
  }
}

Future<void> _pump(WidgetTester tester, void Function(ConnectionFilters filters) onSearch) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(
        data: fThemeLight,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      home: Scaffold(
        body: ConnectionFilterBar(
          onSearch: onSearch,
          categoryService: _FakeCategoryService(),
          customerService: _FakeCustomerService(),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Filtros'));
  await tester.pumpAndSettle();
}


void main() {
  testWidgets('renders without errors', (tester) async {
    await _pump(tester, (filters) {});

    expect(find.text('Filtros'), findsWidgets);
    expect(find.text('Sócio'), findsWidgets);
    expect(find.text('Logradouro'), findsWidgets);
    expect(find.text('Categoria'), findsWidgets);
  });

  testWidgets('reports null filters after clearing', (tester) async {
    ConnectionFilters? captured;
    await _pump(tester, (filters) => captured = filters);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(captured?.customerId, isNull);
    expect(captured?.addressName, isNull);
    expect(captured?.categoryId, isNull);
    expect(captured?.status, 'active');
  });
}
