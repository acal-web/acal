import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice.dart';
import 'package:acalapp/features/invoices/domain/invoice_candidate.dart';
import 'package:acalapp/features/invoices/presentation/generate_invoices_page.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 0, size: 500, first: true, last: true);

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({required this.candidates, this.generateError});

  final List<InvoiceCandidate> candidates;
  Object? generateError;

  DateTime? lastEligibleReference;
  bool? lastHasWaterMeter;
  String? lastAddressId;
  List<String>? lastGeneratedIds;

  @override
  Future<List<InvoiceCandidate>> eligible({required DateTime reference, bool? hasWaterMeter, String? addressId}) async {
    lastEligibleReference = reference;
    lastHasWaterMeter = hasWaterMeter;
    lastAddressId = addressId;
    return candidates;
  }

  @override
  Future<List<Invoice>> generate({required List<String> connectionIds, required DateTime reference, required DateTime dueDate}) async {
    lastGeneratedIds = connectionIds;
    if (generateError != null) throw generateError!;
    return [
      for (final id in connectionIds) Invoice(id: 'inv-$id', connectionId: id, referenceDate: reference, dueDate: dueDate, amount: 20),
    ];
  }
}

class _FakeAddressService extends AddressService {
  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, String? kind, bool? active = true, String? sort, bool sortAscending = true}) async =>
      const PagedResult(data: [], pagination: _pagination);
}

const _candidateA = InvoiceCandidate(
  connectionId: 'c1',
  customerName: 'Fulano de Tal',
  addressName: 'Avenida Fernando Daltro',
  categoryName: 'Residente',
  amount: 20.0,
);

const _candidateB = InvoiceCandidate(
  connectionId: 'c2',
  customerName: 'Beltrano da Silva',
  addressName: 'Rua das Flores',
  categoryName: 'Especial',
  amount: 15.0,
);

Future<void> _pump(WidgetTester tester, {required InvoiceService invoiceService}) async {
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
      home: GenerateInvoicesPage(
        invoiceService: invoiceService,
        addressService: _FakeAddressService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pickDueDate(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('due-date-field')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

// AppToast is a process-wide singleton overlay — draining its auto-dismiss
// timer and closing animation here (instead of pumpAndSettle, which never
// settles while the timer is pending) keeps a leftover timer from crashing
// the next test that shows a toast.
Future<void> _confirmGenerate(WidgetTester tester) async {
  await tester.tap(find.text('Confirmar Geração'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 4));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('loads eligible connections for the current month, all pre-selected', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA, _candidateB]);
    await _pump(tester, invoiceService: service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Beltrano da Silva'), findsOneWidget);
    expect(find.text(formatBRL(20.0)), findsOneWidget);
    expect(find.text('Total (2)'), findsOneWidget);
    expect(find.text(formatBRL(35.0)), findsOneWidget);

    final now = DateTime.now();
    expect(service.lastEligibleReference, DateTime(now.year, now.month));

    final checkboxes = tester.widgetList<FCheckbox>(find.byType(FCheckbox));
    expect(checkboxes.every((c) => c.value == true), isTrue);
  });

  testWidgets('unchecking a candidate excludes it from the total and from generation', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA, _candidateB]);
    await _pump(tester, invoiceService: service);

    // Checkboxes in tree order: header "select all", then one per row.
    await tester.tap(find.byType(FCheckbox).at(2));
    await tester.pumpAndSettle();

    expect(find.text('Total (1)'), findsOneWidget);
    expect(find.text(formatBRL(20.0)), findsWidgets);

    await _pickDueDate(tester);
    await _confirmGenerate(tester);

    expect(service.lastGeneratedIds, ['c1']);
  });

  testWidgets('Confirmar Geração is disabled until a due date is picked', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA]);
    await _pump(tester, invoiceService: service);

    final button = tester.widget<FButton>(find.ancestor(
      of: find.text('Confirmar Geração'),
      matching: find.byType(FButton),
    ));
    expect(button.onPress, isNull);

    await _pickDueDate(tester);

    final enabledButton = tester.widget<FButton>(find.ancestor(
      of: find.text('Confirmar Geração'),
      matching: find.byType(FButton),
    ));
    expect(enabledButton.onPress, isNotNull);
  });

  testWidgets('shows a success toast and reloads the list after generating', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA]);
    await _pump(tester, invoiceService: service);

    await _pickDueDate(tester);
    await tester.tap(find.text('Confirmar Geração'));
    await tester.pump();

    expect(find.text('Faturas geradas com sucesso.'), findsOneWidget);
    expect(service.lastGeneratedIds, ['c1']);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('shows an error toast when generation fails', (tester) async {
    final service = _FakeInvoiceService(
      candidates: [_candidateA],
      generateError: ApiException(422, {'code': 1001, 'message': 'Invoice already exists'}),
    );
    await _pump(tester, invoiceService: service);

    await _pickDueDate(tester);
    await tester.tap(find.text('Confirmar Geração'));
    await tester.pump();

    expect(find.text('Já existe um registro com esses dados.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
