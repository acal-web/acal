import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/widget/connection_form_page.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);

class _FakeCustomerService extends CustomerService {
  _FakeCustomerService(this.items);
  final List<Customer> items;

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
    final filtered =
        (name == null || name.isEmpty) ? items : items.where((c) => c.name.toLowerCase().contains(name.toLowerCase())).toList();
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

class _FakeAddressService extends AddressService {
  _FakeAddressService(this.items);
  final List<Address> items;

  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async {
    final filtered =
        (name == null || name.isEmpty) ? items : items.where((a) => a.name.toLowerCase().contains(name.toLowerCase())).toList();
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

class _FakeCategoryService extends CategoryService {
  _FakeCategoryService(this.items);
  final List<Category> items;

  @override
  Future<PagedResult<Category>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async {
    final filtered =
        (name == null || name.isEmpty) ? items : items.where((c) => c.name.toLowerCase().contains(name.toLowerCase())).toList();
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

class _FakeConnectionService extends ConnectionService {
  _FakeConnectionService(this.error);
  final ApiException error;

  @override
  Future<Connection> create(Connection connection) async => throw error;
}

const _customer = Customer(id: 'cust1', name: 'Fulano de Tal', document: '12345678909', voter: true);
const _address = Address(id: 'addr1', name: 'Rua Principal');
const _category = Category(id: 'cat1', name: 'Padrão', group: 'efetivo', hasWaterMeter: true, waterPrice: 12.5, membershipPrice: 30);

Future<void> _pump(WidgetTester tester, {ConnectionService? connectionService}) async {
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
      home: Scaffold(
        body: ConnectionFormPage(
          connectionService: connectionService,
          customerService: _FakeCustomerService([_customer]),
          addressService: _FakeAddressService([_address]),
          categoryService: _FakeCategoryService([_category]),
        ),
      ),
    ),
  );
}

Future<void> _settleSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

// Field order in ConnectionFormPage: [Número, Letra], Categoria, Data da Matrícula.
// TextFormFields and DropdownMenu render TextField widgets in tree order.
Finder _numberField() => find.byType(TextField).at(2);
Finder _letterField() => find.byType(TextField).at(3);
Finder _categoryField() => find.byType(TextField).at(4);

// With RawAutocomplete, SearchSelectField renders a single visible TextField.
Finder _customerSearchField() => find.byType(TextField).at(0);
Finder _addressSearchField() => find.byType(TextField).at(1);

Future<void> _fillAllFields(WidgetTester tester) async {
  // Customer search
  await tester.enterText(_customerSearchField(), 'fulano');
  await _settleSearch(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Fulano de Tal'));
  await tester.pumpAndSettle();
  // Tap somewhere neutral to close any overlays
  await tester.tap(find.byType(Scaffold));
  await tester.pumpAndSettle();

  // Address search
  await tester.enterText(_addressSearchField(), 'principal');
  await _settleSearch(tester);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('Rua Principal').last);
  await tester.pumpAndSettle();

  await tester.enterText(_numberField(), '12');

  // Categoria uses CategorySelectField (Material DropdownMenu) —
  // it shows its options immediately without typing.
  await tester.tap(_categoryField());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Padrão'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('fails required validation when no picker has been filled', (tester) async {
    await _pump(tester);

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isFalse);
    await tester.pumpAndSettle();

    expect(find.text('Obrigatório'), findsNWidgets(4));
  });

  testWidgets('selecting an option in each picker satisfies validation', (tester) async {
    await _pump(tester);

    await _fillAllFields(tester);

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });

  testWidgets('Letra is optional and limited to a single character', (tester) async {
    await _pump(tester);
    await _fillAllFields(tester);

    await tester.enterText(_letterField(), 'AB');
    await tester.pump();

    final field = tester.widget<TextField>(_letterField());
    expect(field.controller!.text, 'A');

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });

  testWidgets('the Ativa checkbox defaults to checked and can be toggled off', (tester) async {
    await _pump(tester);

    var checkbox = tester.widget<FCheckbox>(find.byType(FCheckbox).at(0));
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(FCheckbox).at(0));
    await tester.pumpAndSettle();

    checkbox = tester.widget<FCheckbox>(find.byType(FCheckbox).at(0));
    expect(checkbox.value, isFalse);
  });

  testWidgets('the Exclusivamente Sócio checkbox defaults to unchecked and can be toggled on', (tester) async {
    await _pump(tester);

    var checkbox = tester.widget<FCheckbox>(find.byType(FCheckbox).at(1));
    expect(checkbox.value, isFalse);

    await tester.tap(find.byType(FCheckbox).at(1));
    await tester.pumpAndSettle();

    checkbox = tester.widget<FCheckbox>(find.byType(FCheckbox).at(1));
    expect(checkbox.value, isTrue);
  });

  testWidgets('picking a membership date fills the field with dd/MM/yyyy', (tester) async {
    await _pump(tester);

    // Full TextField order: Sócio(0), Logradouro(1), Número(2), Letra(3),
    // Categoria(4), Data da Matrícula(5).
    final dateField = find.byType(TextField).at(5);

    await tester.tap(dateField);
    await tester.pumpAndSettle();

    // The Material date picker defaults to today — just confirm a pick
    // closes the dialog and fills the field with *some* dd/MM/yyyy value,
    // without pinning down "today" as a magic value that breaks tomorrow.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(dateField);
    expect(field.controller!.text, matches(RegExp(r'^\d{2}/\d{2}/\d{4}$')));
  });

  testWidgets('shows a clear message when the address already has an active connection', (tester) async {
    await _pump(
      tester,
      connectionService: _FakeConnectionService(ApiException(422, {
        'address_id': [ 'already has an active connection' ],
      })),
    );

    await _fillAllFields(tester);
    await tester.tap(find.widgetWithText(FButton, 'Salvar'));
    await tester.pump();

    expect(find.text('Este logradouro já está com uma ligação ativa.'), findsOneWidget);

    // Drain the toast's auto-dismiss timer and closing animation — AppToast
    // is a process-wide singleton, so a pending timer here leaks into (and
    // crashes) the next test that shows a toast.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('shows a clear message when the customer is already efetivo in another active connection', (tester) async {
    await _pump(
      tester,
      connectionService: _FakeConnectionService(ApiException(422, {
        'customer_id': [ 'already has an active connection as efetivo' ],
      })),
    );

    await _fillAllFields(tester);
    await tester.tap(find.widgetWithText(FButton, 'Salvar'));
    await tester.pump();

    expect(find.text('Este sócio já está recebendo outra ligação como efetivo.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
