import 'package:acalapp/core/layout/app_shell.dart';
import 'package:acalapp/core/layout/menu/side_menu.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class _StubPage extends StatelessWidget {
  const _StubPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FButton(
        onPress: () => AppToast.success(context, 'Feito com sucesso.'),
        child: const Text('Mostrar toast'),
      ),
    );
  }
}

// Mirrors production setup exactly: MaterialApp.router's builder installs
// FTheme + FToaster around the routed content, same as main.dart.
GoRouter _router() => GoRouter(
      initialLocation: '/test',
      routes: [
        ShellRoute(
          builder: (_, _, child) => AppShell(body: child),
          routes: [
            GoRoute(path: '/test', builder: (_, _) => const _StubPage()),
            GoRoute(path: '/customers', builder: (_, _) => const Center(child: Text('Customers Page'))),
          ],
        ),
      ],
    );

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final currentUser = CurrentUser();
  currentUser.setSession(
    AuthUser(id: 'user-1', username: 'testuser', name: 'Test User', role: UserRole.administrador),
    'test-token',
  );

  await tester.pumpWidget(
    CurrentUserScope(
      notifier: currentUser,
      child: MaterialApp.router(
        routerConfig: _router(),
        builder: (context, child) => FTheme(
          data: fThemeLight,
          child: FToaster(child: FTooltipGroup(child: child!)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the menu toggle keeps working after a toast is shown', (tester) async {
    await _pump(tester);
    expect(find.byType(SideMenu), findsOneWidget);

    await tester.tap(find.text('Mostrar toast'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Feito com sucesso.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SideMenu), findsNothing);
  });

  testWidgets('a menu item still navigates after a toast is shown', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Mostrar toast'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Feito com sucesso.'), findsOneWidget);

    await tester.tap(find.text('Sócios'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Customers Page'), findsOneWidget);
  });

  testWidgets('the top-right user menu still opens after a toast is shown', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('Mostrar toast'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Feito com sucesso.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Sair'), findsOneWidget);
  });
}
