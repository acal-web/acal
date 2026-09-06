import 'package:acalapp/core/layout/app_shell.dart';
import 'package:acalapp/features/addresses/presentation/addresses_page.dart';
import 'package:acalapp/features/auth/domain/user_role.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/auth/presentation/login_page.dart';
import 'package:acalapp/features/auth/presentation/splash_page.dart';
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

const _splash = '/splash';
const _login = '/login';
const _dashboard = '/dashboard';
const _portalPrefix = '/portal';
const _portalInvoices = '$_portalPrefix/invoices';

/// Call this from main.dart to initialize the router with CurrentUser — the
/// single login covers both staff and sócio accounts; which area a session
/// lands in (and stays confined to) is decided purely by its role below.
void initializeRouter(Listenable currentUser) {
  appRouter = GoRouter(
    initialLocation: _splash,
    refreshListenable: currentUser,
    redirect: _redirect,
    routes: [
    GoRoute(
      path: _splash,
      pageBuilder: (context, state) => const NoTransitionPage(child: SplashPage()),
    ),
    GoRoute(
      path: _login,
      pageBuilder: (context, state) => const NoTransitionPage(child: LoginPage()),
    ),
    GoRoute(
      path: _portalInvoices,
      pageBuilder: (context, state) => const NoTransitionPage(child: MyInvoicesPage()),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(body: child),
      routes: [
        GoRoute(
          path: _dashboard,
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

/// A session still being validated is neither logged in nor out — hold on
/// the splash screen instead of bouncing through /login while that resolves.
/// Once resolved, keeps the user confined to their area (portal for sócios,
/// everything else for staff) and out of /login and /splash.
String? _redirect(BuildContext context, GoRouterState state) {
  final session = CurrentUserScope.of(context);
  final location = state.matchedLocation;

  if (session.isChecking) {
    return location == _splash ? null : _splash;
  }
  if (!session.isAuthenticated) {
    return location == _login ? null : _login;
  }

  final isCustomer = session.user?.role == UserRole.customer;
  final home = isCustomer ? _portalInvoices : _dashboard;
  final onOwnArea = isCustomer ? location.startsWith(_portalPrefix) : !location.startsWith(_portalPrefix);
  final isEntryRoute = location == _login || location == _splash;

  return (isEntryRoute || !onOwnArea) ? home : null;
}
