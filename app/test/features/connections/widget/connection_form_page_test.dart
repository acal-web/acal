import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/theme/light_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/widget/connection_form_page.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);

class _FakeCustomerService extends CustomerService {
  _FakeCustomerService(this.items);
  final List<Customer> items;

  @override
  Future<PagedResult<Customer>> findAll({int page = 0, int size = 10, String? name, String? document}) async {
    final filtered =
        (name == null || name.isEmpty) ? items : items.where((c) => c.name.toLowerCase().contains(name.toLowerCase())).toList();
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

class _FakeAddressService extends AddressService {
  _FakeAddressService(this.items);
  final List<Address> items;

  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name}) async {
    final filtered =
        (name == null || name.isEmpty) ? items : items.where((a) => a.name.toLowerCase().contains(name.toLowerCase())).toList();
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

class _FakeCategoryService extends CategoryService {
  _FakeCategoryService(this.items);
  final List<Category> items;

  @override
  Future<PagedResult<Category>> findAll({int page = 0, int size = 10, String? name}) async {
    final filtered =
        (name == null || name.isEmpty) ? items : items.where((c) => c.name.toLowerCase().contains(name.toLowerCase())).toList();
    return PagedResult(data: filtered, pagination: _pagination);
  }
}

const _customer = Customer(id: 'cust1', name: 'Fulano de Tal', document: '12345678909', voter: true);
const _address = Address(id: 'addr1', kind: 'Rua', name: 'Principal');
const _category = Category(id: 'cat1', name: 'Padrão', group: 'efetivo', hasWaterMeter: true, waterPrice: 12.5, membershipPrice: 30);

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: ConnectionFormPage(
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

// Field order in ConnectionFormPage: Sócio, Logradouro, Categoria.
Finder _customerField() => find.byType(TextField).at(0);
Finder _addressField() => find.byType(TextField).at(1);
Finder _categoryField() => find.byType(TextField).at(2);

void main() {
  testWidgets('fails required validation when no picker has been filled', (tester) async {
    await _pump(tester);

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isFalse);
    await tester.pump();

    expect(find.text('Obrigatório'), findsNWidgets(3));
  });

  testWidgets('selecting an option in each picker satisfies validation', (tester) async {
    await _pump(tester);

    await tester.enterText(_customerField(), 'fulano');
    await _settleSearch(tester);
    await tester.tap(find.text('Fulano de Tal'));
    await tester.pump();

    await tester.enterText(_addressField(), 'principal');
    await _settleSearch(tester);
    await tester.tap(find.text('Rua Principal'));
    await tester.pump();

    await tester.tap(_categoryField());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Padrão').last);
    await tester.pumpAndSettle();

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });

  testWidgets('the Ativa checkbox defaults to checked and can be toggled off', (tester) async {
    await _pump(tester);

    var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);
  });
}
