import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/presentation/categories_page.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

const _category = Category(
  id: 'cat-1',
  name: 'Mensal',
  group: 'efetivo',
  hasWaterMeter: true,
  waterPrice: 10.0,
  membershipPrice: 30.0,
);

class _FakeCategoryService extends CategoryService {
  _FakeCategoryService({List<Category>? categories}) : categories = categories ?? [_category];

  List<Category> categories;
  Category? created;
  String? deletedId;

  @override
  Future<PagedResult<Category>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    bool? active = true,
    String? sort,
    bool sortAscending = true,
  }) async =>
      PagedResult(
        data: categories,
        pagination: Pagination(number: 0, totalPages: 1, totalElements: categories.length, size: size, first: true, last: true),
      );

  @override
  Future<Category> create(Category category) async {
    created = category;
    final saved = Category(
      id: 'cat-new',
      name: category.name,
      group: category.group,
      hasWaterMeter: category.hasWaterMeter,
      waterPrice: category.waterPrice,
      membershipPrice: category.membershipPrice,
    );
    categories = [...categories, saved];
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    deletedId = id;
    categories = categories.where((c) => c.id != id).toList();
  }
}

Future<void> _pump(WidgetTester tester, CategoryService categoryService) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CategoriesPage(categoryService: categoryService),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists categories with water meter and prices', (tester) async {
    await _pump(tester, _FakeCategoryService());

    expect(find.text('Efetivo Mensal'), findsOneWidget);
    expect(find.text(formatBRL(40.0)), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no categories', (tester) async {
    await _pump(tester, _FakeCategoryService(categories: []));

    expect(find.text('Nenhuma categoria cadastrada.'), findsOneWidget);
  });

  testWidgets('creating a category through the modal saves it with the fake service and refreshes the list', (tester) async {
    final service = _FakeCategoryService(categories: [_category]);
    await _pump(tester, service);

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Nova Categoria'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('category_form_name_field')), 'Anual');
    await tester.enterText(find.byKey(const Key('category_form_water_price_field')), '500');
    await tester.enterText(find.byKey(const Key('category_form_membership_price_field')), '1500');

    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(service.created?.name, 'Anual');
    expect(service.created?.group, 'temporario');
    expect(find.text('Categoria criada com sucesso.'), findsOneWidget);
    expect(find.text('Efetivo Anual'), findsNothing);
    expect(find.text('Temporário Anual'), findsOneWidget);
  });

  testWidgets('deleting a row confirms and removes it from the list', (tester) async {
    final service = _FakeCategoryService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm_button')));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'cat-1');
    expect(find.text('Nenhuma categoria cadastrada.'), findsOneWidget);
  });
}
