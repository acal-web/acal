import 'package:acalapp/features/auth/data/token_storage.dart';
import 'package:acalapp/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// PatrolTester is the type patrolWidgetTest hands to its callback.
// `package:patrol` hides it from its re-export, so it comes straight from
// patrol_finders here.
import 'package:patrol_finders/patrol_finders.dart';

import 'e2e_config.dart';

/// Wide enough to stay above `LayoutConfig.menuBreakpoint` (768) and
/// `narrowBreakpoint` (640): the side menu stays open, forms render as centered
/// dialogs instead of bottom sheets, and the list renders rows instead of
/// cards. Without pinning it, the surface the CI runner happens to give us
/// would decide which of two layouts the suite is testing.
const _wideSurface = Size(1400, 1000);

/// Optional pause after each UI action, so a run can be followed by eye.
/// Off by default; turn it on with `--dart-define=E2E_SLOWMO_MS=800`.
const _slowMoMs = int.fromEnvironment('E2E_SLOWMO_MS');

/// Holds the frame for [_slowMoMs] before the next action. Call it at the end
/// of anything that changes what is on screen.
Future<void> slowMo(PatrolTester $) async {
  if (_slowMoMs > 0) await $.pump(const Duration(milliseconds: _slowMoMs));
}

/// Boots the real app from `main()` on a clean session.
///
/// Clearing [TokenStorage] first matters: a previous scenario in the same run
/// leaves a token behind, and `CurrentUser.restore()` would revalidate it
/// against a JWT that outlives `/test/reset` — the next scenario would start
/// already logged in and never see the login screen.
Future<void> bootApp(PatrolTester $) async {
  await TokenStorage.delete();

  $.tester.view.physicalSize = _wideSurface;
  $.tester.view.devicePixelRatio = 1;
  addTearDown($.tester.view.resetPhysicalSize);
  addTearDown($.tester.view.resetDevicePixelRatio);

  app.main();

  // SplashPage shows an FCircularProgress, which never stops animating, so a
  // plain pumpAndSettle only returns because the redirect happens to land
  // first. pumpAndTrySettle plus an explicit wait makes that deterministic.
  await $.pumpAndTrySettle();
}

Future<void> loginAsAdmin(PatrolTester $) async {
  await bootApp($);

  await $.waitUntilVisible(find.byKey(const Key('login_username_field')));
  await $(const Key('login_username_field')).enterText(e2eAdminUsername);
  await $(const Key('login_password_field')).enterText(e2eAdminPassword);
  await $(const Key('login_submit_button')).tap();

  await $.waitUntilVisible(find.text('Dashboard'));
  await slowMo($);
}

/// Navigates through the side menu, e.g. `openMenu($, 'Categorias')`.
Future<void> openMenu(PatrolTester $, String label) async {
  await $(label).tap();
  await $.pumpAndSettle();
  await slowMo($);
}

/// Picks [optionLabel] in the forui `FSelect` carrying [key].
///
/// `FSelect` does not respond to Patrol's hit-testing tap, so the select itself
/// has to be opened with a raw `tapAt` on its center. The option in the popover
/// taps normally.
Future<void> selectOption(PatrolTester $, Key key, String optionLabel) async {
  await $.tester.tapAt($.tester.getCenter(find.byKey(key)));
  await $.pumpAndSettle();
  await slowMo($);
  await $(optionLabel).tap();
  await $.pumpAndSettle();
  await slowMo($);
}

/// Waits out the 500 ms debounce a filter bar puts in front of every search.
///
/// A pending Timer schedules no frames, so pumpAndSettle returns before the
/// search has even been issued — the pump below is what makes it fire.
Future<void> settleSearchDebounce(PatrolTester $) async {
  await $.pump(const Duration(milliseconds: 600));
  await $.pumpAndSettle();
  await slowMo($);
}

/// Opens the "Filtros" panel, which every "Cadastros" page renders collapsed.
Future<void> openFilters(PatrolTester $, Key toggleKey) async {
  await $(toggleKey).tap();
  await $.pumpAndSettle();
  await slowMo($);
}

/// `AppToast` renders a floating SnackBar that lingers for 4 seconds. Asserting
/// on it and then draining it keeps a leftover toast from matching the next
/// step's expectations.
Future<void> expectToast(PatrolTester $, String message) async {
  expect($(message), findsOneWidget);
  await slowMo($);
  await dismissToast($);
}

Future<void> dismissToast(PatrolTester $) async {
  ScaffoldMessenger.of($.tester.element(find.byType(Scaffold).first)).hideCurrentSnackBar();
  await $.pumpAndSettle();
}
