import 'package:acalapp/core/config/router.dart';
import 'package:acalapp/core/theme/modernist_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Flutter Web renders to <canvas> and only builds the semantics tree lazily;
  // Maestro (and other web a11y tooling) needs it built up front to find elements.
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
      theme: modernistTheme,
      routerConfig: appRouter,
    );
  }
}
