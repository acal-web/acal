import 'package:acalapp/features/users/data/users_service.dart';
import 'package:acalapp/features/users/domain/user_model.dart';
import 'package:acalapp/features/users/presentation/users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _userJson({
  required String id,
  required String username,
  required String name,
  String role = 'administrador',
  String? deletedAt,
}) =>
    {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
      'deleted_at': deletedAt,
    };

class _FakeUsersService extends UsersService {
  _FakeUsersService({List<Map<String, dynamic>>? users}) : users = users ?? [_userJson(id: 'u1', username: 'admin', name: 'Fulano de Tal')];

  List<Map<String, dynamic>> users;
  String? deletedId;
  String? restoredId;
  Map<String, dynamic>? created;

  @override
  Future<Map<String, dynamic>> listUsers({int page = 0, int size = 10}) async => {'content': users};

  @override
  Future<void> deleteUser(String id) async {
    deletedId = id;
    users = users.map((u) => u['id'] == id ? {...u, 'deleted_at': '2026-01-01T00:00:00Z'} : u).toList();
  }

  @override
  Future<UserModel> restoreUser(String id) async {
    restoredId = id;
    users = users.map((u) => u['id'] == id ? {...u, 'deleted_at': null} : u).toList();
    return UserModel.fromJson(users.firstWhere((u) => u['id'] == id));
  }
}

Future<void> _pump(WidgetTester tester, UsersService service) async {
  await tester.pumpWidget(MaterialApp(home: UsersPage(usersService: service)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists users with name, username and role', (tester) async {
    await _pump(tester, _FakeUsersService());

    expect(find.text('Fulano de Tal'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no users', (tester) async {
    await _pump(tester, _FakeUsersService(users: []));

    expect(find.text('Nenhum usuário encontrado'), findsOneWidget);
  });

  testWidgets('deleting a user through the menu confirms and marks it inactive', (tester) async {
    final service = _FakeUsersService();
    await _pump(tester, service);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'u1');
    expect(find.text('Inativo'), findsOneWidget);
  });

  testWidgets('restoring an inactive user calls restore and reloads', (tester) async {
    final service = _FakeUsersService(users: [_userJson(id: 'u2', username: 'inativo', name: 'Ciclano', deletedAt: '2026-01-01T00:00:00Z')]);
    await _pump(tester, service);

    expect(find.text('Inativo'), findsOneWidget);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restaurar'));
    await tester.pumpAndSettle();

    expect(service.restoredId, 'u2');
    expect(find.text('Inativo'), findsNothing);
  });
}
