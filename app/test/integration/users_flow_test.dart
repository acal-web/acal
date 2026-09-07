// See test/integration/categories_flow_test.dart for what this tier covers
// and why it's plain flutter_test rather than package:integration_test.
import 'package:acalapp/features/users/data/users_service.dart';
import 'package:acalapp/features/users/domain/user_model.dart';
import 'package:acalapp/features/users/presentation/users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUsersService extends UsersService {
  final List<Map<String, dynamic>> _users = [];
  int _nextId = 1;

  @override
  Future<Map<String, dynamic>> listUsers({int page = 0, int size = 10}) async => {'content': _users};

  @override
  Future<UserModel> createUser({required String username, required String name, required String password, required String role}) async {
    final json = {
      'id': 'user-${_nextId++}',
      'username': username,
      'name': name,
      'role': role,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': null,
    };
    _users.add(json);
    return UserModel.fromJson(json);
  }
}

Future<void> _pump(WidgetTester tester, UsersService service) async {
  await tester.pumpWidget(MaterialApp(home: UsersPage(usersService: service)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('creates a staff user through the form page and it appears in the list', (tester) async {
    final service = _FakeUsersService();
    await _pump(tester, service);

    expect(find.text('Nenhum usuário encontrado'), findsOneWidget);

    await tester.tap(find.text('Novo'));
    await tester.pumpAndSettle();

    expect(find.text('Novo Usuário'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('user_form_username_field')), 'tesoureiro1');
    await tester.enterText(find.byKey(const Key('user_form_name_field')), 'Fulano de Tal');
    await tester.enterText(find.byKey(const Key('user_form_password_field')), 'senha-forte-123');
    await tester.tap(find.byKey(const Key('user_form_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum usuário encontrado'), findsNothing);
    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('tesoureiro1'), findsOneWidget);
    expect(service._users.single['role'], 'administrador');
  });
}
