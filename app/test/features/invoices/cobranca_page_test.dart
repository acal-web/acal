import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/overdue_connection.dart';
import 'package:acalapp/features/invoices/presentation/cobranca_page.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _address = Address(id: 'addr-1', name: 'Avenida Fernando Daltro');

final _group = OverdueConnection(
  connectionId: 'conn-1',
  connectionNumber: '12A',
  customerName: 'Fulano de Tal',
  addressName: 'Avenida Fernando Daltro',
  invoices: [
    OverdueInvoice(id: 'inv-1', referenceDate: DateTime(2026, 6, 1), dueDate: DateTime(2026, 6, 10), membershipValue: 15.0, waterValue: 5.0),
    OverdueInvoice(id: 'inv-2', referenceDate: DateTime(2026, 7, 1), dueDate: DateTime(2026, 7, 10), membershipValue: 15.0, waterValue: 5.0),
  ],
  totalAmount: 40.0,
  daysOverdue: 45,
);

final _cutoffGroup = OverdueConnection(
  connectionId: 'conn-2',
  connectionNumber: '30B',
  customerName: 'Sicrano de Tal',
  addressName: 'Rua Quintino Alves',
  invoices: [
    OverdueInvoice(id: 'inv-3', referenceDate: DateTime(2026, 1, 1), dueDate: DateTime(2026, 1, 10), membershipValue: 15.0, waterValue: 5.0),
  ],
  totalAmount: 20.0,
  daysOverdue: 200,
  subjectToCutoff: true,
);

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({required this.groups, this.totalAmount = 40.0});

  final List<OverdueConnection> groups;
  final double totalAmount;
  int? lastDays;
  String? lastAddressId;
  int? lastPage;
  String? lastPdfAddressId;

  @override
  Future<({PagedResult<OverdueConnection> page, double totalAmount})> overdue({
    int page = 0,
    int size = 25,
    int? days,
    String? addressId,
  }) async {
    lastDays = days;
    lastAddressId = addressId;
    lastPage = page;
    return (
      page: PagedResult(
        data: groups,
        pagination: Pagination(
          number: page,
          totalPages: 1,
          totalElements: groups.length,
          size: size,
          first: true,
          last: true,
        ),
      ),
      totalAmount: totalAmount,
    );
  }
}

class _FakeAddressService extends AddressService {
  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async =>
      const PagedResult(
        data: [_address],
        pagination: Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true),
      );
}

Future<void> _pump(WidgetTester tester, InvoiceService invoiceService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CobrancaPage(invoiceService: invoiceService, addressService: _FakeAddressService()),
  ));
  await tester.pumpAndSettle();
}

/// Opens the collapsed "Filtros" panel so its fields can be driven.
Future<void> _openFilters(WidgetTester tester) async {
  await tester.tap(find.text('Filtros'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists connections with overdue invoices', (tester) async {
    final service = _FakeInvoiceService(groups: [_group]);
    await _pump(tester, service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12A'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(formatBRL(40.0)), findsWidgets);
  });

  testWidgets('shows an empty message when nothing is overdue', (tester) async {
    final service = _FakeInvoiceService(groups: []);
    await _pump(tester, service);

    expect(find.text('Nenhuma fatura vencida encontrada.'), findsOneWidget);
  });

  testWidgets('disables the download-all button when there is nothing overdue', (tester) async {
    final service = _FakeInvoiceService(groups: []);
    await _pump(tester, service);

    final button = tester.widget<FButton>(find.byType(FButton).first);
    expect(button.onPress, isNull);
  });

  testWidgets('shows the record count and the open total in the footer', (tester) async {
    final service = _FakeInvoiceService(groups: [_group], totalAmount: 260.5);
    await _pump(tester, service);

    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);
    expect(find.text('Total em aberto: ${formatBRL(260.5)}'), findsOneWidget);
  });

  testWidgets('changing the days threshold re-fetches with the new value', (tester) async {
    final service = _FakeInvoiceService(groups: [_group]);
    await _pump(tester, service);

    expect(service.lastDays, 30);

    await _openFilters(tester);
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 dias').last);
    await tester.pumpAndSettle();

    expect(service.lastDays, 60);
    expect(service.lastPage, 0);
  });

  testWidgets('picking a street re-fetches filtered by that address', (tester) async {
    final service = _FakeInvoiceService(groups: [_group]);
    await _pump(tester, service);

    expect(service.lastAddressId, isNull);

    await _openFilters(tester);
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_address.name).last);
    await tester.pumpAndSettle();

    expect(service.lastAddressId, _address.id);
    expect(service.lastPage, 0);
  });

  testWidgets('warns about connections past the cutoff threshold', (tester) async {
    final service = _FakeInvoiceService(groups: [_group, _cutoffGroup]);
    await _pump(tester, service);

    expect(
      find.text('1 ligação com débitos vencidos há mais de $cutoffDays dias — serviço passível de corte.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no cutoff warning when nothing crossed the threshold', (tester) async {
    final service = _FakeInvoiceService(groups: [_group]);
    await _pump(tester, service);

    expect(find.textContaining('passível de corte'), findsNothing);
  });
}
