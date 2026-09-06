import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Shown only while [CurrentUser.restore] is validating a stored session —
/// the router redirects here (never to `/login`) whenever auth status is
/// [AuthStatus.checking], so a returning user never sees the login screen
/// flash before landing on their real destination.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: FCircularProgress()),
    );
  }
}
