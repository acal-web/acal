// See test/integration/categories_flow_test.dart for what this tier covers
// and why it's plain flutter_test rather than package:integration_test.
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/notifications/data/notification_service.dart';
import 'package:acalapp/features/notifications/domain/app_notification.dart';
import 'package:acalapp/features/notifications/presentation/notifications_page.dart';
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

class _FakeNotificationService extends NotificationService {
  final List<AppNotification> _sent = [];

  @override
  Future<PagedResult<AppNotification>> findAll({int page = 0, int size = 20}) async => PagedResult(
        data: _sent,
        pagination: Pagination(number: 0, totalPages: 1, totalElements: _sent.length, size: size, first: true, last: true),
      );

  @override
  Future<int> recipientsCount({String? addressId, String? categoryId, String? status}) async => 7;

  @override
  Future<AppNotification> send({required String title, required String body, String? addressId, String? categoryId, String? status}) async {
    final notification = AppNotification(title: title, body: body, recipientCount: 7);
    _sent.add(notification);
    return notification;
  }
}

Future<void> _pump(WidgetTester tester, NotificationService service) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: NotificationsPage(
      notificationService: service,
      addressService: _FakeAddressService(),
      categoryService: _FakeCategoryService(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sending a notification from the list page shows it in the history afterwards', (tester) async {
    final service = _FakeNotificationService();
    await _pump(tester, service);

    expect(find.text('Nenhuma notificação enviada ainda.'), findsOneWidget);

    await tester.tap(find.text('Nova notificação'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Manutenção programada');
    await tester.enterText(find.byType(TextField).at(1), 'A rede será interrompida às 22h.');
    await tester.tap(find.text('Enviar notificação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.text('Manutenção programada'), findsOneWidget);
    expect(find.text('Nenhuma notificação enviada ainda.'), findsNothing);
    expect(service._sent, hasLength(1));
  });
}
