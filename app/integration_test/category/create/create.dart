import 'dart:convert';

import 'package:acalapp/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

const _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');
const _adminUsername = String.fromEnvironment('E2E_ADMIN_USERNAME', defaultValue: 'e2e_admin');
const _adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD', defaultValue: 'e2e_password123');

Future<String> _login(String username, String password) async {
  final response = await http.post(
    Uri.parse('$_apiBaseUrl/session'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'session': {'username': username, 'password': password},
    }),
  );
  return (jsonDecode(response.body) as Map<String, dynamic>)['token'] as String;
}

Future<void> _resetBackendWithFreshAdmin() async {
  final token = await _login(_adminUsername, _adminPassword);

  await http.post(
    Uri.parse('$_apiBaseUrl/test/reset'),
    headers: {'Authorization': 'Bearer $token'},
  );

  await http.post(
    Uri.parse('$_apiBaseUrl/users'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({
      'user': {
        'username': _adminUsername,
        'name': 'Administrador',
        'password': _adminPassword,
        'role': 'administrador',
      },
    }),
  );
}

Future<void> _createCategory({
  required String name,
  required String group,
}) async {
  final token = await _login(_adminUsername, _adminPassword);

  await http.post(
    Uri.parse('$_apiBaseUrl/categories'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({
      'category': {
        'name': name,
        'description': 'seed',
        'group': group,
        'has_water_meter': false,
        'water_price': 10.0,
        'membership_price': 30.0,
      },
    }),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Usuários', () {
    group('criar', () {
      setUp(_resetBackendWithFreshAdmin);

      patrolWidgetTest('admin cadastra um novo usuário e ele fica salvo no backend', ($) async {
        const newUsername = 'e2e_staff';
        const newUserName = 'E2E Staff User';
        const newUserPassword = 'e2e_password456';
        const newUserRoleLabel = 'Financeiro/Secretaria';
        const newUserRoleValue = 'financeiro_secretaria';

        app.main();
        await $.pumpAndSettle();

        // --- Login ---
        await $(const Key('login_username_field')).enterText(_adminUsername);
        await $(const Key('login_password_field')).enterText(_adminPassword);
        await $(const Key('login_submit_button')).tap();
        await $.pumpAndSettle();

        // --- Navegar até Usuários ---
        await $('Usuários').tap();
        await $.pumpAndSettle();

        // --- Abrir o formulário de criação ---
        await $('Novo').tap();
        await $.pumpAndSettle();

        // --- Preencher o formulário ---
        await $(const Key('user_form_username_field')).enterText(newUsername);
        await $(const Key('user_form_name_field')).enterText(newUserName);
        await $(const Key('user_form_password_field')).enterText(newUserPassword);

        await $(const Key('user_form_role_dropdown')).tap();
        await $.pumpAndSettle();
        await $(newUserRoleLabel).tap();
        await $.pumpAndSettle();

        await $(const Key('user_form_submit_button')).tap();
        await $.pumpAndSettle();

        // --- Asserções na UI ---
        expect($('Usuário criado com sucesso'), findsOneWidget);
        expect($(newUsername), findsOneWidget);
        expect($(newUserName), findsOneWidget);

        // --- Verificação server-side, direto na API Rails (sem usar o token interno do app) ---
        final token = await _login(_adminUsername, _adminPassword);

        final listResponse = await http.get(
          Uri.parse('$_apiBaseUrl/users'),
          headers: {'Authorization': 'Bearer $token'},
        );
        final users = (jsonDecode(listResponse.body) as Map<String, dynamic>)['content'] as List;
        final created = users.cast<Map<String, dynamic>>().firstWhere(
              (u) => u['username'] == newUsername,
              orElse: () => throw StateError('usuário $newUsername não encontrado em GET /users'),
            );

        expect(created['name'], newUserName);
        expect(created['role'], newUserRoleValue);
      });
    });
  });

  group('Categoria', () {
    group('criar', () {
      const existingName = 'Categoria Teste';
      const existingGroup = 'efetivo';
      const existingGroupLabel = 'Efetivo';

      setUp(() async {
        await _resetBackendWithFreshAdmin();
        await _createCategory(name: existingName, group: existingGroup);
      });

      patrolWidgetTest('rejeita categoria duplicada', ($) async {
        app.main();
        await $.pumpAndSettle();

        // --- Login ---
        await $(const Key('login_username_field')).enterText(_adminUsername);
        await $(const Key('login_password_field')).enterText(_adminPassword);
        await $(const Key('login_submit_button')).tap();
        await $.pumpAndSettle();

        // --- Navegar até Categorias ---
        await $('Categorias').tap();
        await $.pumpAndSettle();

        // --- Abrir o formulário de criação ---
        await $('Adicionar').tap();
        await $.pumpAndSettle();

        // --- Preencher com os MESMOS nome+grupo da categoria já existente ---
        await $(const Key('category_form_name_field')).enterText(existingName);

        // FSelect (forui) não responde ao tap por hit-test do Patrol — usa tapAt.
        await $.tester.tapAt($.tester.getCenter(find.byKey(const Key('category_form_group_select'))));
        await $.pumpAndSettle();
        await $(existingGroupLabel).tap();
        await $.pumpAndSettle();

        await $(const Key('category_form_water_price_field')).enterText('1000');
        await $(const Key('category_form_membership_price_field')).enterText('3000');

        await $('Salvar').tap();
        await $.pumpAndSettle();

        // --- Asserções: erro de duplicidade, formulário continua aberto ---
        expect($('Já existe um registro com esses dados.'), findsOneWidget);
        expect($('Nova Categoria'), findsOneWidget);
      });
    });
  });
}
