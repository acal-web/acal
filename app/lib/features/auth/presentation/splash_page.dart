import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: FCircularProgress()),
    );
  }
}
