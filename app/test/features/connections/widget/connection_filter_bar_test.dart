import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/connections/widget/connection_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _pagination = Pagination(number: 0, totalPages: 1, totalElements: 1, size: 10, first: true, last: true);
const _category = Category(id: 'cat1', name: 'Padrão', group: 'efetivo', hasWaterMeter: true, waterPrice: 12.5, membershipPrice: 30);

class _FakeCategoryService extends CategoryService {
  @override
  Future<PagedResult<Category>> findAll({int page = 0, int size = 10, String? name}) async {
    return const PagedResult(data: [_category], pagination: _pagination);
  }
}

Future<void> _pump(WidgetTester tester, void Function(ConnectionFilters filters) onSearch) async {
  tester.view.physicalSize = const Size(1400, 900);
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
        body: ConnectionFilterBar(onSearch: onSearch, categoryService: _FakeCategoryService()),
      ),
    ),
  );

  // The filter section starts collapsed — expand it and let the reveal
  // animation finish so the fields are hit-testable for the rest of the test.
  await tester.tap(find.text('Filtros'));
  await tester.pumpAndSettle();
}

Future<void> _settleSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

// Text field order: Sócio (nome), Documento, Logradouro, Categoria (search),
// Situação.
Finder _customerNameField() => find.byType(TextField).at(0);
Finder _customerDocumentField() => find.byType(TextField).at(1);
Finder _addressNameField() => find.byType(TextField).at(2);
Finder _categoryField() => find.byType(TextField).at(3);
Finder _situacaoField() => find.byType(TextField).at(4);

// The popover opened by Categoria's SearchSelectField (FSelect.searchBuilder)
// inserts its own inner search TextField wherever the field sits in the
// tree — not necessarily at the end — so it can't be reached via
// `find.byType(TextField).last`. Its default hint ("Search", from Forui's
// un-localized default) is stable enough to target.
Finder _openSearchPopoverField() => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Search');

void main() {
  testWidgets('reports trimmed sócio name, digits-only document and logradouro name on search', (tester) async {
    ConnectionFilters? captured;
    await _pump(tester, (filters) => captured = filters);

    await tester.enterText(_customerNameField(), '  Fulano  ');
    await tester.enterText(_customerDocumentField(), '123.456.789-09');
    await tester.enterText(_addressNameField(), '  Principal  ');
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(captured?.customerName, 'Fulano');
    expect(captured?.customerDocument, '12345678909');
    expect(captured?.addressName, 'Principal');
  });

  testWidgets('reports the selected category and active status on search', (tester) async {
    ConnectionFilters? captured;
    await _pump(tester, (filters) => captured = filters);

    await tester.tap(_categoryField());
    await tester.pump();
    await tester.enterText(_openSearchPopoverField(), 'padr');
    await _settleSearch(tester);
    await tester.tap(find.text('Padrão'));
    await tester.pumpAndSettle();

    await tester.tap(_situacaoField());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ativas').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(captured?.categoryId, 'cat1');
    expect(captured?.active, isTrue);
  });

  testWidgets('clearing resets all fields and reports no filters', (tester) async {
    var searchCalls = 0;
    ConnectionFilters? captured;
    await _pump(tester, (filters) {
      searchCalls++;
      captured = filters;
    });

    await tester.enterText(_customerNameField(), 'Fulano');
    await tester.enterText(_addressNameField(), 'Principal');

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(searchCalls, 1);
    expect(captured?.customerName, isNull);
    expect(captured?.customerDocument, isNull);
    expect(captured?.addressName, isNull);
    expect(captured?.categoryId, isNull);
    expect(captured?.active, isNull);
    expect(find.text('Fulano'), findsNothing);
  });
}
