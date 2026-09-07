// "Integration" here means: multiple widgets (list, filter bar, create/edit
// modal, delete confirmation) exercised together as one whole-page flow
// against an in-memory fake CategoryService, rather than a single widget in
// isolation. It intentionally does NOT use package:integration_test — that
// package's binding only runs on a real device (needs `-d <device>`, and on
// Linux desktop a full CMake build), so it can't run headlessly. This stays
// plain flutter_test so it runs with the rest of the suite: no device, no
// Rails backend, no Patrol.
//
// The real device-driven, real-backend suite lives in ../../integration_test
// (Patrol) — this is the lighter tier below it.
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/presentation/categories_page.dart' show CategoriesPage, categoryRowKey;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _FakeCategoryService extends CategoryService {
  final List<Category> _categories = [];
  int _nextId = 1;

  @override
  Future<PagedResult<Category>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    bool? active = true,
    String? sort,
    bool sortAscending = true,
  }) async {
    final filtered = _categories.where((c) => c.active == (active ?? true)).toList();
    return PagedResult(
      data: filtered,
      pagination: Pagination(number: 0, totalPages: 1, totalElements: filtered.length, size: size, first: true, last: true),
    );
  }

  @override
  Future<Category> create(Category category) async {
    final saved = Category(
      id: 'cat-${_nextId++}',
      name: category.name,
      group: category.group,
      hasWaterMeter: category.hasWaterMeter,
      waterPrice: category.waterPrice,
      membershipPrice: category.membershipPrice,
    );
    _categories.add(saved);
    return saved;
  }

  @override
  Future<Category> update(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    _categories[index] = category;
    return category;
  }

  @override
  Future<void> delete(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    _categories[index] = Category(
      id: _categories[index].id,
      name: _categories[index].name,
      group: _categories[index].group,
      hasWaterMeter: _categories[index].hasWaterMeter,
      waterPrice: _categories[index].waterPrice,
      membershipPrice: _categories[index].membershipPrice,
      active: false,
    );
  }
}

Future<void> _pump(WidgetTester tester, CategoryService service) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CategoriesPage(categoryService: service),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates, edits and deletes a category through the full page flow', (tester) async {
    final service = _FakeCategoryService();
    // The wide layout only draws its header (and with it the "Adicionar"
    // button) once the table has at least one row — seed an anchor so the
    // create flow below has a button to tap, same as the Patrol E2E suite
    // does for the same reason (see integration_test/category/category_test.dart).
    await service.create(const Category(name: 'Ancora', group: 'temporario', hasWaterMeter: false, waterPrice: 0, membershipPrice: 0));
    await _pump(tester, service);

    expect(find.text('Temporário Ancora'), findsOneWidget);

    // Create.
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category_form_name_field')), 'Mensal');
    await tester.enterText(find.byKey(const Key('category_form_water_price_field')), '1000');
    await tester.enterText(find.byKey(const Key('category_form_membership_price_field')), '3000');
    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Categoria criada com sucesso.'), findsOneWidget);
    expect(find.text('Temporário Mensal'), findsOneWidget);

    // Edit — scoped to the "Mensal" row since "Ancora" also has row actions.
    final mensalRow = find.byKey(categoryRowKey('temporario', 'Mensal'));
    await tester.tap(find.descendant(of: mensalRow, matching: find.byKey(const Key('row_action_edit'))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('category_form_name_field')), 'Mensal Reajustada');
    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Categoria atualizada com sucesso.'), findsOneWidget);
    expect(find.text('Temporário Mensal Reajustada'), findsOneWidget);
    expect(find.text('Temporário Mensal'), findsNothing);

    // Delete.
    final reajustadaRow = find.byKey(categoryRowKey('temporario', 'Mensal Reajustada'));
    await tester.tap(find.descendant(of: reajustadaRow, matching: find.byKey(const Key('row_action_delete'))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm_button')));
    await tester.pumpAndSettle();

    expect(find.text('Temporário Mensal Reajustada'), findsNothing);
    expect(find.text('Temporário Ancora'), findsOneWidget);
  });
}
