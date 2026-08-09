import 'package:acalapp/core/config/router.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: materialThemeLight,
      routerConfig: appRouter,
      // pt-BR only — the app has no other locale. Mainly benefits stock
      // Material widgets we still use directly, e.g. showDatePicker.
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => FTheme(
        data: fThemeLight,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
    );
  }
}
