import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/notifications/data/notification_service.dart';
import 'package:acalapp/features/notifications/domain/app_notification.dart';
import 'package:acalapp/features/notifications/presentation/send_notification_page.dart';
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
  int recipientCount = 3;
  String? sentTitle;
  String? sentBody;

  @override
  Future<int> recipientsCount({String? addressId, String? categoryId, String? status}) async => recipientCount;

  @override
  Future<AppNotification> send({
    required String title,
    required String body,
    String? addressId,
    String? categoryId,
    String? status,
  }) async {
    sentTitle = title;
    sentBody = body;
    return AppNotification(title: title, body: body);
  }
}

Future<void> _pump(WidgetTester tester, {required NotificationService notificationService}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(
        data: fThemeLight,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      home: SendNotificationPage(
        notificationService: notificationService,
        addressService: _FakeAddressService(),
        categoryService: _FakeCategoryService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a character counter that respects the title and body max length', (tester) async {
    final service = _FakeNotificationService();
    await _pump(tester, notificationService: service);

    expect(find.text('0/65'), findsOneWidget);
    expect(find.text('0/1000'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Manutenção programada');
    await tester.pump();

    expect(find.text('21/65'), findsOneWidget);
  });

  testWidgets('shows the live recipient count from the filters and sends after confirmation', (tester) async {
    final service = _FakeNotificationService()..recipientCount = 7;
    await _pump(tester, notificationService: service);

    expect(find.text('7 sócios receberão esta notificação.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Aviso');
    await tester.enterText(find.byType(TextField).at(1), 'Mensagem de teste');
    await tester.tap(find.text('Enviar notificação'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(service.sentTitle, 'Aviso');
    expect(service.sentBody, 'Mensagem de teste');
  });
}
