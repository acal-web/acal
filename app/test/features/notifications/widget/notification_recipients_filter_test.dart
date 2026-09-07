import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/notifications/widget/notification_recipients_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 0, size: 10, first: true, last: true);

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

Future<void> _pump(WidgetTester tester, ValueChanged<RecipientFilters> onChanged) async {
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
      body: NotificationRecipientsFilter(
        onChanged: onChanged,
        addressService: _FakeAddressService(),
        categoryService: _FakeCategoryService(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders address, category and status fields', (tester) async {
    await _pump(tester, (_) {});

    expect(find.text('Situação'), findsOneWidget);
  });

  testWidgets('changing status emits the new filters', (tester) async {
    RecipientFilters? captured;
    await _pump(tester, (filters) => captured = filters);

    // FSelect doesn't open from a tap on its label text — it needs a raw
    // tapAt its center, same workaround the Patrol E2E suite's
    // `selectOption` helper uses (see integration_test/support/app_driver.dart).
    await tester.tapAt(tester.getCenter(
      find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('_BasicSelect<RecipientStatus>')),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(captured?.status, 'all');
    expect(captured?.addressId, isNull);
    expect(captured?.categoryId, isNull);
  });
}
