import 'dart:async';

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Auto-discovered by the test runner for every test under this directory.
///
/// Widget tests substitute any unloaded font family with a synthetic test
/// font that renders far wider glyphs than real type. forui's default theme
/// requests `packages/forui/Inter`, so anything sized to fit real text (e.g.
/// `AddButton` inside a table header's fixed-width column) overflows in tests
/// even though it renders fine in the app. Loading forui's actual bundled
/// font here keeps test layout measurements in line with production.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = await rootBundle.load('packages/forui/assets/fonts/inter/Inter.ttf');
  await (FontLoader('packages/forui/Inter')..addFont(Future.value(data))).load();

  // The app's MaterialApp initializes pt_BR date symbols as a side effect of
  // its `localizationsDelegates`/`supportedLocales` setup (see lib/main.dart).
  // A bare `MaterialApp` in a widget test skips that, so any `DateFormat(...,
  // 'pt_BR')` throws LocaleDataException unless this is done explicitly.
  await initializeDateFormatting();

  await testMain();
}
