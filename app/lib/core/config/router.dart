import 'package:acalapp/core/layout/app_shell.dart';
import 'package:acalapp/features/addresses/presentation/addresses_page.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/auth/presentation/login_page.dart';
import 'package:acalapp/features/customer_portal/presentation/my_invoices_page.dart';
import 'package:acalapp/features/users/presentation/users_page.dart';
import 'package:acalapp/features/cashbox/presentation/cashbox_page.dart';
import 'package:acalapp/features/categories/presentation/categories_page.dart';
import 'package:acalapp/features/connections/presentation/connections_page.dart';
import 'package:acalapp/features/dashboard/presentation/dashboard_page.dart';
import 'package:acalapp/features/documentation/presentation/documentation_page.dart';
import 'package:acalapp/features/elections/presentation/elections_page.dart';
import 'package:acalapp/features/invoices/presentation/cobranca_page.dart';
import 'package:acalapp/features/invoices/presentation/generate_invoices_page.dart';
import 'package:acalapp/features/invoices/presentation/invoices_page.dart';
import 'package:acalapp/features/notifications/presentation/notifications_page.dart';
import 'package:acalapp/features/quality/presentation/quality_page.dart';
import 'package:acalapp/features/customer/presentation/customer_page.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

late GoRouter appRouter;

/// Call this from main.dart to initialize the router with CurrentUser — the
/// single login covers both staff and sócio accounts; which area a session
/// lands in (and stays confined to) is decided purely by its role below.
void initializeRouter(Listenable currentUser) {
  appRouter = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: currentUser,
    redirect: (context, state) {
      final session = CurrentUserScope.of(context);
      final isAuthenticated = session.isAuthenticated;
      final isCustomer = session.user?.role == UserRole.customer;
      final goingToLogin = state.matchedLocation == '/login';
      final isPortalRoute = state.matchedLocation.startsWith('/portal');

      if (!isAuthenticated) {
        return goingToLogin ? null : '/login';
      }

      if (goingToLogin) {
        return isCustomer ? '/portal/invoices' : '/dashboard';
      }

      // Sócios stay confined to the portal; staff never lands there.
      if (isCustomer && !isPortalRoute) return '/portal/invoices';
      if (!isCustomer && isPortalRoute) return '/dashboard';

      return null;
    },
    routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
    ),
    GoRoute(
      path: '/portal/invoices',
      pageBuilder: (context, state) => const NoTransitionPage(child: MyInvoicesPage()),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(body: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (context, state) => const NoTransitionPage(child: CustomersPage()),
        ),
        GoRoute(
          path: '/addresses',
          pageBuilder: (context, state) => const NoTransitionPage(child: AddressesPage()),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => const NoTransitionPage(child: CategoriesPage()),
        ),
        GoRoute(
          path: '/connections',
          pageBuilder: (context, state) => const NoTransitionPage(child: ConnectionsPage()),
        ),
        GoRoute(
          path: '/quality',
          pageBuilder: (context, state) => const NoTransitionPage(child: QualityPage()),
        ),
        GoRoute(
          path: '/invoices/generate',
          pageBuilder: (context, state) => const NoTransitionPage(child: GenerateInvoicesPage()),
        ),
        GoRoute(
          path: '/invoices/cobranca',
          pageBuilder: (context, state) => const NoTransitionPage(child: CobrancaPage()),
        ),
        GoRoute(
          path: '/invoices',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 300),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            child: const InvoicesPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(secondaryAnimation),
                child: child,
              );
            },
          ),
        ),
        GoRoute(
          path: '/cashbox',
          pageBuilder: (context, state) => const NoTransitionPage(child: CashboxPage()),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsPage()),
        ),
        GoRoute(
          path: '/users',
          pageBuilder: (context, state) => const NoTransitionPage(child: UsersPage()),
        ),
        GoRoute(
          path: '/elections',
          pageBuilder: (context, state) => const NoTransitionPage(child: ElectionsPage()),
        ),
        GoRoute(
          path: '/documentation',
          pageBuilder: (context, state) => const NoTransitionPage(child: DocumentationPage()),
        ),
      ],
    ),
  ],
  );
}
