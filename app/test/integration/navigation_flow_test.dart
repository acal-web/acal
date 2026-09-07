// Covers the one thing a single-page widget test structurally can't: real
// go_router navigation between two pages inside AppShell, driven by a
// logged-in CurrentUserScope session — here with a fake AuthUser/session and
// a fake CategoryService, no real backend and no full `app.main()` boot.
import 'package:acalapp/core/layout/app_shell.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/auth/domain/auth_user.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/presentation/categories_page.dart';
import 'package:acalapp/features/dashboard/presentation/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

const _category = Category(
  id: 'cat-1',
  name: 'Mensal',
  group: 'efetivo',
  hasWaterMeter: true,
  waterPrice: 10,
  membershipPrice: 30,
);

class _FakeCategoryService extends CategoryService {
  @override
  Future<PagedResult<Category>> findAll({
    int page = 0,
    int size = 10,
    String? name,
    bool? active = true,
    String? sort,
    bool sortAscending = true,
  }) async =>
      const PagedResult(
        data: [_category],
        pagination: Pagination(number: 0, totalPages: 1, totalElements: 1, size: 25, first: true, last: true),
      );
}

// Mirrors lib/core/config/router.dart's shape (ShellRoute wrapping AppShell)
// with just the routes this flow needs, so the fake services can be wired in
// directly instead of through the real screens' default constructors.
GoRouter _router(CategoryService categoryService) => GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (_, _, child) => AppShell(body: child),
          routes: [
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
            GoRoute(path: '/categories', builder: (_, _) => CategoriesPage(categoryService: categoryService)),
          ],
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, CategoryService categoryService) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final currentUser = CurrentUser();
  currentUser.setSession(
    AuthUser(id: 'user-1', username: 'admin', name: 'Fulano de Tal', role: UserRole.administrador),
    'test-token',
  );

  await tester.pumpWidget(
    CurrentUserScope(
      notifier: currentUser,
      child: MaterialApp.router(
        routerConfig: _router(categoryService),
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
  testWidgets('navigates from the dashboard to a feature page and back through the side menu', (tester) async {
    await _pump(tester, _FakeCategoryService());

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Categorias'), findsOneWidget);

    await tester.tap(find.text('Categorias'));
    await tester.pumpAndSettle();

    expect(find.text('Efetivo Mensal'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Resumo financeiro.'), findsOneWidget);
    expect(find.text('Efetivo Mensal'), findsNothing);
  });
}
