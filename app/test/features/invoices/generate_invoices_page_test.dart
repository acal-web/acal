import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
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
  _FakeInvoiceService({required this.candidates});

  final List<InvoiceCandidate> candidates;

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
  Future<List<Invoice>> generate({
    required List<String> connectionIds,
    required DateTime reference,
    required DateTime dueDate,
    List<Map<String, dynamic>>? waterMeters,
  }) async {
    lastGeneratedIds = connectionIds;
    return [
      for (final id in connectionIds) Invoice(id: 'inv-$id', connectionId: id, referenceDate: reference, dueDate: dueDate, membershipValue: 15, waterValue: 5),
    ];
  }
}

class _FakeAddressService extends AddressService {
  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async =>
      const PagedResult(data: [], pagination: _pagination);
}

const _candidateA = InvoiceCandidate(
  connectionId: 'c1',
  customerName: 'Fulano de Tal',
  addressName: 'Avenida Fernando Daltro',
  number: 123,
  letter: 'A',
  categoryName: 'Residente',
  membershipValue: 15.0,
  waterValue: 5.0,
  hasWaterMeter: true,
  previousMeterFinalReading: 1000.0,
);

const _candidateB = InvoiceCandidate(
  connectionId: 'c2',
  customerName: 'Beltrano da Silva',
  addressName: 'Rua das Flores',
  number: 456,
  letter: null,
  categoryName: 'Especial',
  membershipValue: 10.0,
  waterValue: 5.0,
  hasWaterMeter: false,
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

void main() {
  testWidgets('loads eligible connections and displays candidates', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA, _candidateB]);
    await _pump(tester, invoiceService: service);

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('Beltrano da Silva'), findsOneWidget);

    final now = DateTime.now();
    expect(service.lastEligibleReference, DateTime(now.year, now.month));
  });

  testWidgets('has confirmation button and due date field', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA]);
    await _pump(tester, invoiceService: service);

    expect(find.text('Confirmar Geração'), findsOneWidget);
    expect(find.byKey(const Key('due-date-field')), findsOneWidget);
  });

  testWidgets('tapping anywhere on a row toggles its selection, same as the checkbox', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA, _candidateB]);
    await _pump(tester, invoiceService: service);

    expect(find.text('Total (0)'), findsOneWidget);

    await tester.tap(find.text('Fulano de Tal'));
    await tester.pumpAndSettle();
    expect(find.text('Total (1)'), findsOneWidget);

    await tester.tap(find.text('Fulano de Tal'));
    await tester.pumpAndSettle();
    expect(find.text('Total (0)'), findsOneWidget);
  });

  testWidgets('tapping/typing in the water meter fields does not toggle row selection', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA]);
    await _pump(tester, invoiceService: service);

    // Field order in the tree: the period filter's reference field, then this
    // row's initial/final meter readings (candidate A is the only row and has
    // a water meter), then the generate bar's due-date field.
    final initialReadingField = find.byType(FTextFormField).at(1);

    await tester.tap(initialReadingField);
    await tester.pumpAndSettle();
    expect(find.text('Total (0)'), findsOneWidget);

    await tester.enterText(initialReadingField, '1500');
    await tester.pumpAndSettle();
    expect(find.text('Total (0)'), findsOneWidget);
  });

  testWidgets('previews the excess-water charge live as meter readings are typed', (tester) async {
    final service = _FakeInvoiceService(candidates: [_candidateA]);
    await _pump(tester, invoiceService: service);

    // Base amount (membership 15 + water 5), no readings yet.
    expect(find.text(formatBRL(20)), findsOneWidget);

    final initialReadingField = find.byType(FTextFormField).at(1);
    final finalReadingField = find.byType(FTextFormField).at(2);

    // 11000 - 0 = 1000L over the 10000L free tier -> R$4,00 preview extra.
    await tester.enterText(initialReadingField, '0');
    await tester.enterText(finalReadingField, '11000');
    await tester.pumpAndSettle();

    expect(find.text(formatBRL(24)), findsOneWidget);

    await tester.enterText(finalReadingField, '');
    await tester.pumpAndSettle();

    expect(find.text(formatBRL(20)), findsOneWidget);
  });
}
