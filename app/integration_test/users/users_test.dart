import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// patrolWidgetTest and PatrolTester both live in patrol_finders;
// package:patrol only re-exports the former, hiding the latter.
import 'package:patrol_finders/patrol_finders.dart';

import '../support/api.dart';
import '../support/app_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(E2eApi.resetBackendWithFreshAdmin);

  group('Usuários — criar', () {
    patrolWidgetTest('admin cadastra um novo usuário e ele fica salvo no backend', ($) async {
      const newUsername = 'e2e_staff';
      const newUserName = 'E2E Staff User';
      const newUserPassword = 'e2e_password456';
      const newUserRoleLabel = 'Financeiro/Secretaria';
      const newUserRoleValue = 'financeiro_secretaria';

      await loginAsAdmin($);
      await openMenu($, 'Usuários');

      await $('Novo').tap();
      await $.pumpAndSettle();

      await $(const Key('user_form_username_field')).enterText(newUsername);
      await $(const Key('user_form_name_field')).enterText(newUserName);
      await $(const Key('user_form_password_field')).enterText(newUserPassword);

      await $(const Key('user_form_role_dropdown')).tap();
      await $.pumpAndSettle();
      await $(newUserRoleLabel).tap();
      await $.pumpAndSettle();

      await $(const Key('user_form_submit_button')).tap();
      await $.pumpAndSettle();

      expect($('Usuário criado com sucesso'), findsOneWidget);
      expect($(newUsername), findsOneWidget);
      expect($(newUserName), findsOneWidget);

      // Verificação server-side, direto na API (sem usar o token interno do app).
      final token = await E2eApi.login();
      expect(token, isNotEmpty);

      final users = await E2eApi.users();
      final created = users.firstWhere(
        (u) => u['username'] == newUsername,
        orElse: () => throw StateError('usuário $newUsername não encontrado em GET /users'),
      );

      expect(created['name'], newUserName);
      expect(created['role'], newUserRoleValue);
    });
  });
}
