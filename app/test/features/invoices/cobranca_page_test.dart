import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/overdue_connection.dart';
import 'package:acalapp/features/invoices/presentation/cobranca_page.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

final _group = OverdueConnection(
  connectionId: 'conn-1',
  connectionNumber: '12A',
  customerName: 'Fulano de Tal',
  addressName: 'Avenida Fernando Daltro',
  invoices: [
    OverdueInvoice(id: 'inv-1', referenceDate: DateTime(2026, 6, 1), dueDate: DateTime(2026, 6, 10), amount: 20.0),
    OverdueInvoice(id: 'inv-2', referenceDate: DateTime(2026, 7, 1), dueDate: DateTime(2026, 7, 10), amount: 20.0),
  ],
  totalAmount: 40.0,
);

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({required this.groups});

  final List<OverdueConnection> groups;
  int? lastDays;

  @override
  Future<List<OverdueConnection>> overdue({int? days}) async {
    lastDays = days;
    return groups;
  }
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
    home: CobrancaPage(invoiceService: invoiceService),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists connections with overdue invoices', (tester) async {
    final service = _FakeInvoiceService(groups: [_group]);
    await _pump(tester, service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Avenida Fernando Daltro, 12A'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(formatBRL(40.0)), findsOneWidget);
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

  testWidgets('changing the days threshold re-fetches with the new value', (tester) async {
    final service = _FakeInvoiceService(groups: [_group]);
    await _pump(tester, service);

    expect(service.lastDays, 30);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('60 dias').last);
    await tester.pumpAndSettle();

    expect(service.lastDays, 60);
  });
}
