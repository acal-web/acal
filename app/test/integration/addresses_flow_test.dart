// See test/integration/categories_flow_test.dart for what this tier covers
// and why it's plain flutter_test rather than package:integration_test.
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/presentation/addresses_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _FakeAddressService extends AddressService {
  final List<Address> _addresses = [];
  int _nextId = 1;

  @override
  Future<PagedResult<Address>> findAll({int page = 0, int size = 10, String? name, bool? active = true, String? sort, bool sortAscending = true}) async {
    final filtered = _addresses.where((a) => a.active == (active ?? true)).toList();
    return PagedResult(
      data: filtered,
      pagination: Pagination(number: 0, totalPages: 1, totalElements: filtered.length, size: size, first: true, last: true),
    );
  }

  @override
  Future<Address> create(Address address) async {
    final saved = Address(id: 'addr-${_nextId++}', name: address.name);
    _addresses.add(saved);
    return saved;
  }
}

Future<void> _pump(WidgetTester tester, AddressService service) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: AddressesPage(addressService: service),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates an address through the modal and it appears in the list', (tester) async {
    final service = _FakeAddressService();
    // AddressesPage has no stable per-row Key, so this keeps a single row
    // throughout rather than also exercising delete on an ambiguous one —
    // delete is already covered at the widget-test level.
    await service.create(const Address(name: 'Ancora'));
    await _pump(tester, service);

    expect(find.text('Ancora'), findsOneWidget);

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(FTextFormField).first, 'Avenida Nova');
    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Endereço criado com sucesso.'), findsOneWidget);
    expect(find.text('Avenida Nova'), findsOneWidget);
  });
}
