import 'package:acalapp/core/config/router.dart' show initializeRouter, appRouter;
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/auth/presentation/current_user.dart';
import 'package:acalapp/features/auth/presentation/current_user_scope.dart';
import 'package:acalapp/features/customer_portal/presentation/current_customer.dart';
import 'package:acalapp/features/customer_portal/presentation/current_customer_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';

late CurrentUser _currentUser;
late CurrentCustomer _currentCustomer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }

  _currentUser = CurrentUser();
  _currentCustomer = CurrentCustomer();

  setupHttpService(
    getToken: () => _currentUser.token,
    onUnauthorized: () {
      _currentUser.clear();
    },
  );

  initializeRouter(_currentUser, _currentCustomer);

  _currentUser.restore();
  _currentCustomer.restore();

  runApp(MainApp(currentUser: _currentUser, currentCustomer: _currentCustomer));
}

class MainApp extends StatelessWidget {
  final CurrentUser currentUser;
  final CurrentCustomer currentCustomer;

  const MainApp({super.key, required this.currentUser, required this.currentCustomer});

  @override
  Widget build(BuildContext context) {
    return CurrentUserScope(
      notifier: currentUser,
      child: CurrentCustomerScope(
        notifier: currentCustomer,
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
      ),
    );
  }
}
