import 'package:acalapp/features/categories/presentation/categories_page.dart' show categoryRowKey;
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:integration_test/integration_test.dart';
// patrolWidgetTest and PatrolTester both live in patrol_finders;
// package:patrol only re-exports the former, hiding the latter.
import 'package:patrol_finders/patrol_finders.dart';

import '../support/api.dart';
import '../support/app_driver.dart';

const _nameField = Key('category_form_name_field');
const _descriptionField = Key('category_form_description_field');
const _groupSelect = Key('category_form_group_select');
const _waterPriceField = Key('category_form_water_price_field');
const _membershipPriceField = Key('category_form_membership_price_field');
const _waterMeterCheckbox = Key('category_form_water_meter_checkbox');
const _saveButton = Key('form_save_button');
const _cancelButton = Key('form_cancel_button');

const _filterToggle = Key('category_filter_toggle');
const _filterNameField = Key('category_filter_name_field');
const _filterActiveSelect = Key('category_filter_active_select');
const _filterSearchButton = Key('category_filter_search_button');
const _filterClearButton = Key('category_filter_clear_button');

/// A category that only exists so the table renders.
///
/// The wide layout only draws its header — and with it the "Adicionar" button —
/// when the list has at least one row; an empty list renders just the
/// "Nenhuma categoria cadastrada." message. So every scenario that opens the
/// creation form needs the table to be non-empty first.
const _anchorName = 'Ancora';
const _anchorGroup = 'temporario';

Future<void> _seedAnchor() => E2eApi.createCategory(name: _anchorName, group: _anchorGroup);

/// Logs in and lands on the categories page — the starting point of every
/// scenario below. Seeding happens before this, over HTTP.
Future<void> _openCategories(PatrolTester $) async {
  await loginAsAdmin($);
  await openMenu($, 'Categorias');
}

Future<void> _openNewCategoryForm(PatrolTester $) async {
  await $('Adicionar').tap();
  await $.pumpAndSettle();
}

/// Fills the creation/edit form. Prices are typed as raw digits: the currency
/// mask fills them in from the right, so '1000' becomes R$ 10,00.
Future<void> _fillForm(
  PatrolTester $, {
  String? name,
  String? description,
  String? groupLabel,
  String? waterPriceDigits,
  String? membershipPriceDigits,
  bool? hasWaterMeter,
}) async {
  if (name != null) await $(_nameField).enterText(name);
  if (description != null) await $(_descriptionField).enterText(description);
  if (groupLabel != null) await selectOption($, _groupSelect, groupLabel);
  if (waterPriceDigits != null) await $(_waterPriceField).enterText(waterPriceDigits);
  if (membershipPriceDigits != null) {
    await $(_membershipPriceField).enterText(membershipPriceDigits);
  }
  if (hasWaterMeter != null) {
    final current = $.tester.widget<FCheckbox>(find.byKey(_waterMeterCheckbox)).value;
    if (current != hasWaterMeter) {
      await $(_waterMeterCheckbox).tap();
      await $.pumpAndSettle();
    }
  }
}

Future<void> _save(PatrolTester $) async {
  await $(_saveButton).tap();
  await $.pumpAndSettle();
}

/// Runs a filter-bar search and waits out its debounce.
Future<void> _search(PatrolTester $) async {
  await $(_filterSearchButton).tap();
  await settleSearchDebounce($);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(E2eApi.resetBackendWithFreshAdmin);

  group('Categoria — listar', () {
    patrolWidgetTest('mostra o estado vazio quando não há nenhuma categoria', ($) async {
      await _openCategories($);

      expect($('Nenhuma categoria cadastrada.'), findsOneWidget);
    });

    patrolWidgetTest('lista as categorias cadastradas com nome, hidrômetro e valores', ($) async {
      await E2eApi.createCategory(
        name: 'Mensal',
        group: 'efetivo',
        hasWaterMeter: true,
        waterPrice: 10.0,
        membershipPrice: 30.0,
      );
      await E2eApi.createCategory(name: 'Anual', group: 'fundador');
      await E2eApi.createCategory(name: 'Diaria', group: 'temporario');

      await _openCategories($);

      // O nome é renderizado como fullName ("<Grupo> <nome>").
      expect($('Efetivo Mensal'), findsOneWidget);
      expect($('Fundador Anual'), findsOneWidget);
      expect($('Temporário Diaria'), findsOneWidget);

      // A linha da "Mensal": hidrômetro, água, societário e total (soma dos dois).
      final row = $(categoryRowKey('efetivo', 'Mensal'));
      expect(row.$('Sim'), findsOneWidget);
      expect(row.$(formatBRL(10.0)), findsOneWidget);
      expect(row.$(formatBRL(30.0)), findsOneWidget);
      expect(row.$(formatBRL(40.0)), findsOneWidget);

      // A API ordena por nome ascendente: Anual, Diaria, Mensal.
      double topOf(String fullName) => $.tester.getTopLeft(find.text(fullName)).dy;
      expect(topOf('Fundador Anual'), lessThan(topOf('Temporário Diaria')));
      expect(topOf('Temporário Diaria'), lessThan(topOf('Efetivo Mensal')));

      expect($('Mostrando 3 de 3 registros'), findsOneWidget);
    });
  });

  group('Categoria — filtrar', () {
    patrolWidgetTest('filtra por nome e volta a listar tudo ao limpar', ($) async {
      await E2eApi.createCategory(name: 'Mensal', group: 'efetivo');
      await E2eApi.createCategory(name: 'Anual', group: 'fundador');

      await _openCategories($);
      await openFilters($, _filterToggle);

      await $(_filterNameField).enterText('Mens');
      await _search($);

      expect($('Efetivo Mensal'), findsOneWidget);
      expect($('Fundador Anual'), findsNothing);

      await $(_filterClearButton).tap();
      await settleSearchDebounce($);

      expect($('Efetivo Mensal'), findsOneWidget);
      expect($('Fundador Anual'), findsOneWidget);
    });

    patrolWidgetTest('o filtro "Inativas" mostra as excluídas com ações de visualizar e reativar', ($) async {
      final removed = await E2eApi.createCategory(name: 'Antiga', group: 'efetivo');
      await E2eApi.deleteCategory(removed['id'] as String);
      await E2eApi.createCategory(name: 'Atual', group: 'efetivo');

      await _openCategories($);

      expect($('Efetivo Atual'), findsOneWidget);
      expect($('Efetivo Antiga'), findsNothing);

      await openFilters($, _filterToggle);
      await selectOption($, _filterActiveSelect, 'Inativas');
      await _search($);

      final row = $(categoryRowKey('efetivo', 'Antiga'));
      expect(row, findsOneWidget);
      expect($('Efetivo Atual'), findsNothing);

      // Linha inativa troca Editar/Excluir por Visualizar/Reativar.
      expect(row.$(const Key('row_action_view')), findsOneWidget);
      expect(row.$(const Key('row_action_reactivate')), findsOneWidget);
      expect(row.$(const Key('row_action_edit')), findsNothing);
      expect(row.$(const Key('row_action_delete')), findsNothing);
    });
  });

  group('Categoria — criar', () {
    patrolWidgetTest('cria uma categoria e ela fica salva no backend', ($) async {
      await _seedAnchor();
      await _openCategories($);
      await _openNewCategoryForm($);

      await _fillForm(
        $,
        name: 'Mensal',
        description: 'Sócio efetivo mensal',
        groupLabel: 'Efetivo',
        waterPriceDigits: '1000',
        membershipPriceDigits: '3000',
        hasWaterMeter: true,
      );
      await _save($);

      await expectToast($, 'Categoria criada com sucesso.');
      expect($('Nova Categoria'), findsNothing);

      final row = $(categoryRowKey('efetivo', 'Mensal'));
      expect(row, findsOneWidget);
      expect(row.$(formatBRL(40.0)), findsOneWidget);

      final saved = await E2eApi.findCategory(name: 'Mensal', group: 'efetivo');
      expect(saved, isNotNull);
      expect(saved!['description'], 'Sócio efetivo mensal');
      expect(saved['has_water_meter'], isTrue);
      expect(double.parse(saved['water_price'].toString()), 10.0);
      expect(double.parse(saved['membership_price'].toString()), 30.0);
    });

    patrolWidgetTest('rejeita categoria duplicada e mantém o formulário aberto', ($) async {
      await E2eApi.createCategory(name: 'Categoria Teste', group: 'efetivo');

      await _openCategories($);
      await _openNewCategoryForm($);

      await _fillForm(
        $,
        name: 'Categoria Teste',
        groupLabel: 'Efetivo',
        waterPriceDigits: '1000',
        membershipPriceDigits: '3000',
      );
      await _save($);

      await expectToast($, 'Já existe um registro com esses dados.');
      expect($('Nova Categoria'), findsOneWidget);
    });

    patrolWidgetTest('a duplicidade ignora maiúsculas e minúsculas', ($) async {
      await E2eApi.createCategory(name: 'Categoria Teste', group: 'efetivo');

      await _openCategories($);
      await _openNewCategoryForm($);

      // O índice único do banco é sobre lower(group), lower(name).
      await _fillForm(
        $,
        name: 'categoria teste',
        groupLabel: 'Efetivo',
        waterPriceDigits: '1000',
        membershipPriceDigits: '3000',
      );
      await _save($);

      await expectToast($, 'Já existe um registro com esses dados.');
      expect(await E2eApi.categories(), hasLength(1));
    });

    patrolWidgetTest('aceita o mesmo nome em outro grupo', ($) async {
      await E2eApi.createCategory(name: 'Categoria Teste', group: 'efetivo');

      await _openCategories($);
      await _openNewCategoryForm($);

      await _fillForm(
        $,
        name: 'Categoria Teste',
        groupLabel: 'Fundador',
        waterPriceDigits: '1000',
        membershipPriceDigits: '3000',
      );
      await _save($);

      await expectToast($, 'Categoria criada com sucesso.');
      expect($(categoryRowKey('fundador', 'Categoria Teste')), findsOneWidget);
      expect(await E2eApi.findCategory(name: 'Categoria Teste', group: 'fundador'), isNotNull);
    });

    patrolWidgetTest('não envia nada ao backend quando o nome está vazio', ($) async {
      await _seedAnchor();
      await _openCategories($);
      await _openNewCategoryForm($);

      await _fillForm($, waterPriceDigits: '1000', membershipPriceDigits: '3000');
      await _save($);

      expect($('Obrigatório'), findsOneWidget);
      expect($('Nova Categoria'), findsOneWidget);
      expect(await E2eApi.categories(), hasLength(1));
    });

    patrolWidgetTest('cancelar descarta o formulário sem criar nada', ($) async {
      await _seedAnchor();
      await _openCategories($);
      await _openNewCategoryForm($);

      await _fillForm(
        $,
        name: 'Descartada',
        groupLabel: 'Efetivo',
        waterPriceDigits: '1000',
        membershipPriceDigits: '3000',
      );
      await $(_cancelButton).tap();
      await $.pumpAndSettle();

      expect($('Nova Categoria'), findsNothing);
      expect($(categoryRowKey('efetivo', 'Descartada')), findsNothing);
      expect(await E2eApi.findCategory(name: 'Descartada', group: 'efetivo'), isNull);
    });
  });

  group('Categoria — editar', () {
    patrolWidgetTest('abre o formulário preenchido com os dados da categoria', ($) async {
      await E2eApi.createCategory(
        name: 'Mensal',
        group: 'efetivo',
        description: 'Descrição original',
        hasWaterMeter: true,
        waterPrice: 10.0,
        membershipPrice: 30.0,
      );

      await _openCategories($);
      await $(categoryRowKey('efetivo', 'Mensal')).$(const Key('row_action_edit')).tap();
      await $.pumpAndSettle();

      expect($('Editar Categoria'), findsOneWidget);
      expect($(_nameField).$('Mensal'), findsOneWidget);
      expect($(_descriptionField).$('Descrição original'), findsOneWidget);
      expect($(_groupSelect).$('Efetivo'), findsOneWidget);
      expect($(_waterPriceField).$(formatBRL(10.0)), findsOneWidget);
      expect($(_membershipPriceField).$(formatBRL(30.0)), findsOneWidget);
      expect($.tester.widget<FCheckbox>(find.byKey(_waterMeterCheckbox)).value, isTrue);
    });

    patrolWidgetTest('salva as alterações e a lista reflete os novos valores', ($) async {
      await E2eApi.createCategory(
        name: 'Mensal',
        group: 'efetivo',
        waterPrice: 10.0,
        membershipPrice: 30.0,
      );

      await _openCategories($);
      await $(categoryRowKey('efetivo', 'Mensal')).$(const Key('row_action_edit')).tap();
      await $.pumpAndSettle();

      await _fillForm($, name: 'Mensal Reajustada', waterPriceDigits: '2500');
      await _save($);

      await expectToast($, 'Categoria atualizada com sucesso.');

      final row = $(categoryRowKey('efetivo', 'Mensal Reajustada'));
      expect(row, findsOneWidget);
      expect(row.$(formatBRL(25.0)), findsOneWidget);
      expect(row.$(formatBRL(55.0)), findsOneWidget);
      expect($(categoryRowKey('efetivo', 'Mensal')), findsNothing);

      final saved = await E2eApi.findCategory(name: 'Mensal Reajustada', group: 'efetivo');
      expect(saved, isNotNull);
      expect(double.parse(saved!['water_price'].toString()), 25.0);
      expect(await E2eApi.findCategory(name: 'Mensal', group: 'efetivo'), isNull);
    });

    patrolWidgetTest('rejeita renomear para um par grupo+nome já existente', ($) async {
      await E2eApi.createCategory(name: 'Mensal', group: 'efetivo');
      await E2eApi.createCategory(name: 'Anual', group: 'efetivo');

      await _openCategories($);
      await $(categoryRowKey('efetivo', 'Anual')).$(const Key('row_action_edit')).tap();
      await $.pumpAndSettle();

      await _fillForm($, name: 'Mensal');
      await _save($);

      await expectToast($, 'Já existe um registro com esses dados.');
      expect($('Editar Categoria'), findsOneWidget);
      expect(await E2eApi.findCategory(name: 'Anual', group: 'efetivo'), isNotNull);
    });
  });

  group('Categoria — excluir e reativar', () {
    patrolWidgetTest('cancelar a confirmação não exclui', ($) async {
      await E2eApi.createCategory(name: 'Mensal', group: 'efetivo');

      await _openCategories($);
      await $(categoryRowKey('efetivo', 'Mensal')).$(const Key('row_action_delete')).tap();
      await $.pumpAndSettle();

      expect($('Deseja excluir "Mensal"?'), findsOneWidget);
      await $(const Key('delete_cancel_button')).tap();
      await $.pumpAndSettle();

      expect($(categoryRowKey('efetivo', 'Mensal')), findsOneWidget);
      expect(await E2eApi.findCategory(name: 'Mensal', group: 'efetivo'), isNotNull);
    });

    patrolWidgetTest('excluir remove da lista e faz soft delete no backend', ($) async {
      await E2eApi.createCategory(name: 'Mensal', group: 'efetivo');
      await E2eApi.createCategory(name: 'Anual', group: 'fundador');

      await _openCategories($);
      await $(categoryRowKey('efetivo', 'Mensal')).$(const Key('row_action_delete')).tap();
      await $.pumpAndSettle();
      await $(const Key('delete_confirm_button')).tap();
      await $.pumpAndSettle();

      expect($(categoryRowKey('efetivo', 'Mensal')), findsNothing);
      expect($(categoryRowKey('fundador', 'Anual')), findsOneWidget);

      expect(await E2eApi.findCategory(name: 'Mensal', group: 'efetivo'), isNull);
      final deleted = await E2eApi.findCategory(name: 'Mensal', group: 'efetivo', active: 'false');
      expect(deleted, isNotNull);
      expect(deleted!['deleted_at'], isNotNull);
    });

    patrolWidgetTest('reativar traz a categoria de volta para a lista de ativas', ($) async {
      final removed = await E2eApi.createCategory(name: 'Antiga', group: 'efetivo');
      await E2eApi.deleteCategory(removed['id'] as String);

      await _openCategories($);
      await openFilters($, _filterToggle);
      await selectOption($, _filterActiveSelect, 'Inativas');
      await _search($);

      await $(categoryRowKey('efetivo', 'Antiga')).$(const Key('row_action_reactivate')).tap();
      await $.pumpAndSettle();

      // A lista continua filtrada por inativas, então a categoria some dela.
      expect($(categoryRowKey('efetivo', 'Antiga')), findsNothing);
      expect(await E2eApi.findCategory(name: 'Antiga', group: 'efetivo'), isNotNull);

      await selectOption($, _filterActiveSelect, 'Ativas');
      await _search($);

      expect($(categoryRowKey('efetivo', 'Antiga')), findsOneWidget);
    });

    patrolWidgetTest('visualizar uma categoria inativa abre o formulário somente leitura', ($) async {
      final removed = await E2eApi.createCategory(name: 'Antiga', group: 'efetivo');
      await E2eApi.deleteCategory(removed['id'] as String);

      await _openCategories($);
      await openFilters($, _filterToggle);
      await selectOption($, _filterActiveSelect, 'Inativas');
      await _search($);

      await $(categoryRowKey('efetivo', 'Antiga')).$(const Key('row_action_view')).tap();
      await $.pumpAndSettle();

      expect($('Visualizar Categoria'), findsOneWidget);
      expect($(_nameField).$('Antiga'), findsOneWidget);
      expect($(_saveButton), findsNothing);
      expect($(_cancelButton), findsOneWidget);
    });

    patrolWidgetTest('não permite recriar uma categoria com o mesmo grupo e nome de uma excluída', ($) async {
      await _seedAnchor();
      final removed = await E2eApi.createCategory(name: 'Categoria Teste', group: 'efetivo');
      await E2eApi.deleteCategory(removed['id'] as String);

      await _openCategories($);
      await _openNewCategoryForm($);

      // O índice único do banco não filtra por deleted_at: a linha excluída
      // continua ocupando o par grupo+nome.
      await _fillForm(
        $,
        name: 'Categoria Teste',
        groupLabel: 'Efetivo',
        waterPriceDigits: '1000',
        membershipPriceDigits: '3000',
      );
      await _save($);

      await expectToast($, 'Já existe um registro com esses dados.');
      expect($('Nova Categoria'), findsOneWidget);
    });
  });
}
