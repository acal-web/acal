import 'dart:ui';

import 'package:flutter/material.dart';

/// Shows [builder] centered over a blurred, dimmed backdrop — the standard
/// modal treatment for forms (Novo Endereço, etc.) across the app.
Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: const SizedBox.expand(),
          ),
        ),
        Center(child: Builder(builder: builder)),
      ],
    ),
  );
}
