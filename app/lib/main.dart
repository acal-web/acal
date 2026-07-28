import 'package:acalapp/core/config/router.dart';
import 'package:acalapp/core/theme/light_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: lightTheme,
      routerConfig: appRouter,
    );
  }
}
