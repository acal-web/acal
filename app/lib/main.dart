import 'package:acalapp/core/config/router.dart' show initializeRouter, appRouter;
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

late CurrentUser _currentUser;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  _currentUser = CurrentUser();

  setupHttpService(
    getToken: () => _currentUser.token,
    onUnauthorized: () {
      _currentUser.clear();
    },
  );

  await _currentUser.restore();

  initializeRouter(_currentUser);

  runApp(MainApp(currentUser: _currentUser));
}

class MainApp extends StatelessWidget {
  final CurrentUser currentUser;

  const MainApp({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return CurrentUserScope(
      notifier: currentUser,
      child: MaterialApp.router(
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
      ),
    );
  }
}
