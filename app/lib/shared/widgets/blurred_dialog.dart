import 'dart:ui';

import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';

/// Shows [builder] centered over a blurred, dimmed backdrop — the standard
/// modal treatment for forms (Novo Endereço, etc.) across the app.
///
/// On narrow screens (< 640px), displays as a [ModalBottomSheet] instead.
/// Animations: smooth scale + fade for dialog, slide-up for bottom sheet.
Future<T?> showBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final isNarrow =
      MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

  if (isNarrow) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Builder(builder: builder),
      ),
    );
  }

  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => _AnimatedBlurredDialog(
      builder: builder,
    ),
  );
}

class _AnimatedBlurredDialog extends StatefulWidget {
  final WidgetBuilder builder;

  const _AnimatedBlurredDialog({required this.builder});

  @override
  State<_AnimatedBlurredDialog> createState() => _AnimatedBlurredDialogState();
}

class _AnimatedBlurredDialogState extends State<_AnimatedBlurredDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: const SizedBox.expand(),
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Builder(builder: widget.builder),
            ),
          ),
        ),
      ],
    );
  }
}
