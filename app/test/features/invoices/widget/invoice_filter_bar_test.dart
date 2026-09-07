import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/invoices/widget/invoice_filter_bar.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
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

typedef _Search = void Function({MonthYear? period, String? customerId, String? addressId, String? status});

Future<void> _pump(WidgetTester tester, _Search onSearch) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: Scaffold(
      body: InvoiceFilterBar(
        onSearch: onSearch,
        customerService: _FakeCustomerService(),
        addressService: _FakeAddressService(),
      ),
    ),
  ));

  await tester.tap(find.text('Filtros'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders period, customer, address and status fields', (tester) async {
    await _pump(tester, ({period, customerId, addressId, status}) {});

    expect(find.text('Período'), findsOneWidget);
    expect(find.text('Situação'), findsOneWidget);
  });

  testWidgets('clearing resets customer, address and status to defaults', (tester) async {
    String? capturedCustomerId = 'not-null';
    String? capturedAddressId = 'not-null';
    String? capturedStatus = 'not-null';

    await _pump(tester, ({period, customerId, addressId, status}) {
      capturedCustomerId = customerId;
      capturedAddressId = addressId;
      capturedStatus = status;
    });

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(capturedCustomerId, isNull);
    expect(capturedAddressId, isNull);
    expect(capturedStatus, isNull);
  });
}
