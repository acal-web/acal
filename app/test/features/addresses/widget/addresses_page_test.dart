import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/presentation/addresses_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _address = Address(id: 'addr-1', name: 'Rua Principal');

class _FakeAddressService extends AddressService {
  _FakeAddressService({List<Address>? addresses}) : addresses = addresses ?? [_address];

  List<Address> addresses;
  Address? created;
  String? deletedId;

  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async =>
      PagedResult(
        data: addresses,
        pagination: Pagination(number: 0, totalPages: 1, totalElements: addresses.length, size: size, first: true, last: true),
      );

  @override
  Future<Address> create(Address address) async {
    created = address;
    final saved = Address(id: 'addr-new', name: address.name);
    addresses = [...addresses, saved];
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    deletedId = id;
    addresses = addresses.where((a) => a.id != id).toList();
  }
}

Future<void> _pump(WidgetTester tester, AddressService addressService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: AddressesPage(addressService: addressService),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists addresses', (tester) async {
    await _pump(tester, _FakeAddressService());

    expect(find.text('Rua Principal'), findsOneWidget);
    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no addresses', (tester) async {
    await _pump(tester, _FakeAddressService(addresses: []));

    expect(find.text('Nenhum endereço cadastrado.'), findsOneWidget);
  });

  testWidgets('creating an address through the modal saves it with the fake service', (tester) async {
    final service = _FakeAddressService(addresses: [_address]);
    await _pump(tester, service);

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Novo Endereço'), findsOneWidget);

    await tester.enterText(find.byType(FTextFormField).first, 'Avenida Nova');
    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(service.created?.name, 'Avenida Nova');
    expect(find.text('Endereço criado com sucesso.'), findsOneWidget);
    expect(find.text('Avenida Nova'), findsOneWidget);
  });

  testWidgets('deleting a row confirms and removes it from the list', (tester) async {
    final service = _FakeAddressService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm_button')));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'addr-1');
    expect(find.text('Nenhum endereço cadastrado.'), findsOneWidget);
  });
}
