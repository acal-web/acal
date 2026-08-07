import 'package:acalapp/core/layout/app_shell.dart';
import 'package:acalapp/core/layout/menu/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Mirrors production setup: ShellRoute wraps AppShell, body is a stub page.
GoRouter _router() => GoRouter(
      initialLocation: '/test',
      routes: [
        ShellRoute(
          builder: (_, _, child) => AppShell(body: child),
          routes: [
            GoRoute(path: '/test', builder: (_, _) => const SizedBox()),
          ],
        ),
      ],
    );

    Widget _app(GoRouter router) => MaterialApp.router(
      routerConfig: router,
    );

// Logical pixels — breakpoint is 768.
const _wide   = Size(1024, 768);
const _narrow = Size(400,  800);

void main() {
  group('AppShell — responsive menu', () {
    testWidgets('shows SideMenu on wide screen', (tester) async {
      tester.view.physicalSize = _wide;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();

      expect(find.byType(SideMenu), findsOneWidget);
    });

    testWidgets('hides SideMenu on narrow screen', (tester) async {
      tester.view.physicalSize = _narrow;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();

      expect(find.byType(SideMenu), findsNothing);
    });

    testWidgets('toggle hides SideMenu when visible', (tester) async {
      tester.view.physicalSize = _wide;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      expect(find.byType(SideMenu), findsNothing);
    });

    testWidgets('toggle shows SideMenu when hidden', (tester) async {
      tester.view.physicalSize = _narrow;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      expect(find.byType(SideMenu), findsOneWidget);
    });

    testWidgets('resizing wide → narrow auto-hides menu', (tester) async {
      tester.view.physicalSize = _wide;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();
      expect(find.byType(SideMenu), findsOneWidget);

      tester.view.physicalSize = _narrow;
      await tester.pumpAndSettle();

      expect(find.byType(SideMenu), findsNothing);
    });

    testWidgets('resizing narrow → wide auto-shows menu', (tester) async {
      tester.view.physicalSize = _narrow;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(_router()));
      await tester.pumpAndSettle();
      expect(find.byType(SideMenu), findsNothing);

      tester.view.physicalSize = _wide;
      await tester.pumpAndSettle();

      expect(find.byType(SideMenu), findsOneWidget);
    });
  });
}
