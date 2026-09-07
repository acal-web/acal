import 'package:acalapp/features/auth/data/auth_service.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/auth/presentation/login_page.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.error});

  final Object? error;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<({String token, AuthUser user})> login(String username, String password) async {
    lastUsername = username;
    lastPassword = password;
    if (error != null) throw error!;
    return (
      token: 'test-token',
      user: AuthUser(id: 'user-1', username: username, name: 'Fulano de Tal', role: UserRole.administrador),
    );
  }
}

Future<CurrentUser> _pump(WidgetTester tester, AuthService authService) async {
  final currentUser = CurrentUser(authService: authService);
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: CurrentUserScope(
      notifier: currentUser,
      child: LoginPage(authService: authService),
    ),
  ));
  await tester.pumpAndSettle();
  return currentUser;
}

void main() {
  testWidgets('requires username and password before submitting', (tester) async {
    final service = _FakeAuthService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Usuário e senha são obrigatórios'), findsOneWidget);
    expect(service.lastUsername, isNull);
  });

  testWidgets('shows an error message on invalid credentials', (tester) async {
    final service = _FakeAuthService(error: Exception('invalid credentials'));
    await _pump(tester, service);

    await tester.enterText(find.byKey(const Key('login_username_field')), 'admin');
    await tester.enterText(find.byKey(const Key('login_password_field')), 'wrong-password');
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Falha no login. Verifique suas credenciais.'), findsOneWidget);
  });

  // A successful login isn't covered here: past `AuthService.login`, `_handleLogin`
  // calls `TokenStorage.write`, which talks to the real `flutter_secure_storage`
  // plugin. That plugin has no platform binding in a plain widget test (no
  // device, no libsecret/DBus session), so the awaited call never resolves and
  // `pumpAndSettle` hangs. Exercising the full success path needs either the
  // Patrol/integration_test suite (a real platform) or making `TokenStorage`
  // injectable — out of scope for this pass.
}
