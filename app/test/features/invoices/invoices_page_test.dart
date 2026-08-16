import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/presentation/invoice_detail_page.dart';
import 'package:acalapp/features/invoices/presentation/invoices_page.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart'; // ignore: unused_import

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);

final _connection = Connection(
  id: 'conn-1',
  customerId: 'cust-1',
  addressId: 'addr-1',
  categoryId: 'cat-1',
  number: 12,
  letter: 'A',
  customer: const Customer(id: 'cust-1', name: 'Fulano de Tal', document: '12345678900', voter: false),
  address: const Address(id: 'addr-1', name: 'Avenida Fernando Daltro'),
  category: const Category(
    id: 'cat-1',
    name: 'Residente',
    group: 'efetivo',
    hasWaterMeter: true,
    waterPrice: 15,
    membershipPrice: 5,
  ),
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

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({required this.invoices});

  final List<Invoice> invoices;
  int? lastYear;
  int? lastMonth;
  String? markedPaidId;

  @override
  Future<PagedResult<Invoice>> findAll({
    int page = 0,
    int size = 10,
    int? year,
    int? month,
    String? customerId,
    String? addressId,
    String? status,
    String? sortBy,
    bool? sortAscending,
  }) async {
    lastYear = year;
    lastMonth = month;
    return PagedResult(data: invoices, pagination: _pagination);
  }

  @override
  Future<Invoice> getById(String invoiceId) async {
    return invoices.firstWhere((i) => i.id == invoiceId);
  }

  @override
  Future<Invoice> markPaid(String invoiceId) async {
    markedPaidId = invoiceId;
    final invoice = invoices.firstWhere((i) => i.id == invoiceId);
    return Invoice(
      id: invoice.id,
      connectionId: invoice.connectionId,
      referenceDate: invoice.referenceDate,
      dueDate: invoice.dueDate,
      membershipValue: invoice.membershipValue,
      waterValue: invoice.waterValue,
      paidAt: DateTime.now(),
      connection: invoice.connection,
    );
  }
}

GoRouter _router(InvoiceService invoiceService) => GoRouter(
      initialLocation: '/invoices',
      routes: [
        GoRoute(
          path: '/invoices',
          builder: (_, _) => InvoicesPage(invoiceService: invoiceService),
        ),
        GoRoute(
          path: '/invoices/generate',
          builder: (_, _) => const Scaffold(body: Text('Gerar Faturas Page')),
        ),
        GoRoute(
          path: '/invoices/cobranca',
          builder: (_, _) => const Scaffold(body: Text('Cobranças Page')),
        ),
        GoRoute(
          path: '/invoices/:id',
          builder: (_, state) => InvoiceDetailPage(
            invoiceId: state.pathParameters['id'] ?? '',
            invoiceService: invoiceService,
          ),
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, InvoiceService invoiceService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final currentUser = CurrentUser();
  currentUser.setSession(
    AuthUser(
      id: 'user-1',
      username: 'testuser',
      name: 'Test User',
      role: UserRole.administrador,
    ),
    'test-token',
  );

  await tester.pumpWidget(
    CurrentUserScope(
      notifier: currentUser,
      child: MaterialApp.router(
        routerConfig: _router(invoiceService),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => FTheme(
          data: fThemeLight,
          child: FToaster(child: FTooltipGroup(child: child!)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists invoices with connection, due date and amount', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12A'), findsOneWidget);
    expect(find.text('08/2026'), findsOneWidget);
    expect(find.text('10/08/2026'), findsOneWidget);
    expect(find.text(formatBRL(20.0)), findsOneWidget);
    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);
  });

  testWidgets('shows a placeholder dash when the connection is missing', (tester) async {
    final invoiceWithoutConnection = Invoice(
      id: 'inv-2',
      number: '2026.08.000002',
      connectionId: 'conn-2',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      membershipValue: 15.0,
      waterValue: 5.0,
    );
    final service = _FakeInvoiceService(invoices: [invoiceWithoutConnection]);
    await _pump(tester, service);

    expect(find.text('—'), findsNWidgets(2));
  });

  testWidgets('Gerar Faturas navigates to the generate page', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    await tester.tap(find.text('Gerar Faturas'));
    await tester.pumpAndSettle();

    expect(find.text('Gerar Faturas Page'), findsOneWidget);
  });

  testWidgets('Cobranças navigates to the dunning letters page', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    await tester.tap(find.text('Cobranças'));
    await tester.pumpAndSettle();

    expect(find.text('Cobranças Page'), findsOneWidget);
  });

  testWidgets('marking an invoice as paid calls the service and reloads the list', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    // PopupMenuButton opens to show menu items with icons
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    // Should show "Marcar como Paga" option
    expect(find.text('Marcar como Paga'), findsOneWidget);

    await tester.tap(find.text('Marcar como Paga'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));

    expect(service.markedPaidId, 'inv-1');
  });

  testWidgets('shows a paid indicator instead of the mark-paid action for a paid invoice', (tester) async {
    final paidInvoice = Invoice(
      id: 'inv-3',
      number: '2026.08.000001',
      connectionId: 'conn-1',
      referenceDate: DateTime(2026, 8, 1),
      dueDate: DateTime(2026, 8, 10),
      membershipValue: 15.0,
      waterValue: 5.0,
      paidAt: DateTime(2026, 8, 5),
      connection: _connection,
    );
    final service = _FakeInvoiceService(invoices: [paidInvoice]);
    await _pump(tester, service);

    // PopupMenuButton opens to show menu items
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    // Should show "Paga" status instead of mark-paid option
    expect(find.text('Paga'), findsOneWidget);
    expect(find.text('Marcar como Paga'), findsNothing);
  });

  testWidgets('view action opens the invoice details page', (tester) async {
    final service = _FakeInvoiceService(invoices: [_invoice]);
    await _pump(tester, service);

    // PopupMenuButton opens to show menu items
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();

    // Should show "Visualizar" option as first item
    expect(find.text('Visualizar'), findsOneWidget);

    await tester.tap(find.text('Visualizar'));
    await tester.pumpAndSettle();

    // Should navigate to the invoice detail page with the title
    expect(find.text('Detalhes da Fatura'), findsOneWidget);
  });
}
