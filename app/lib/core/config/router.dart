import 'package:acalapp/core/layout/app_shell.dart';
import 'package:acalapp/features/addresses/presentation/addresses_page.dart';
import 'package:acalapp/features/dashboard/presentation/dashboard_page.dart';
import 'package:acalapp/features/users/presentation/users_page.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(body: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const UsersPage(),
        ),
        GoRoute(
          path: '/addresses',
          builder: (context, state) => const AddressesPage(),
        ),
      ],
    ),
  ],
);
