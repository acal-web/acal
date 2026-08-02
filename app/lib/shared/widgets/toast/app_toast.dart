import 'dart:async';

import 'package:acalapp/core/theme/eva_theme.dart';
import 'package:flutter/material.dart';

enum AppToastType { error, warning, success }

/// Global floating toast — shows error/warning/confirmation messages docked
/// to the top-right of the screen, above dialogs, auto-dismissing after
/// [duration]. Call from anywhere with a [BuildContext].
abstract final class AppToast {
  static final _controller = _AppToastController();

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.warning);

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppToastType.success);

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.error,
    Duration duration = const Duration(seconds: 4),
  }) {
    _controller.show(context, message: message, type: type, duration: duration);
  }
}

class _ToastMessage {
  _ToastMessage({required this.id, required this.text, required this.type});
  final String id;
  final String text;
  final AppToastType type;
}

class _AppToastController extends ChangeNotifier {
  final List<_ToastMessage> _messages = [];
  final Set<String> _closing = {};
  OverlayEntry? _entry;
  int _nextId = 0;

  List<_ToastMessage> get messages => _messages;
  bool isClosing(String id) => _closing.contains(id);

  void show(
    BuildContext context, {
    required String message,
    required AppToastType type,
    required Duration duration,
  }) {
    final id = '${_nextId++}';
    _messages.add(_ToastMessage(id: id, text: message, type: type));

    _entry ??= OverlayEntry(builder: (_) => _ToastStack(controller: this));
    if (_entry!.mounted == false) {
      Overlay.of(context, rootOverlay: true).insert(_entry!);
    }
    notifyListeners();

    Timer(duration, () => close(id));
  }

  Future<void> close(String id) async {
    if (_closing.contains(id) || !_messages.any((m) => m.id == id)) return;
    _closing.add(id);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 180));
    _messages.removeWhere((m) => m.id == id);
    _closing.remove(id);
    notifyListeners();

    if (_messages.isEmpty) {
      _entry?.remove();
      _entry = null;
    }
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack({required this.controller});

  final _AppToastController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Positioned(
        top: 0,
        right: 0,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final message in controller.messages)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _ToastCard(
                      key: ValueKey(message.id),
                      message: message,
                      closing: controller.isClosing(message.id),
                      onClose: () => controller.close(message.id),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required super.key,
    required this.message,
    required this.closing,
    required this.onClose,
  });

  final _ToastMessage message;
  final bool closing;
  final VoidCallback onClose;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard> {
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _entered && !widget.closing;
    final (background, foreground, icon) = switch (widget.message.type) {
      AppToastType.error => (const Color(0xFFBA1A1A), Colors.white, Icons.error_outline),
      AppToastType.warning => (const Color(0xFFB25E00), Colors.white, Icons.warning_amber_outlined),
      AppToastType.success => (const Color(0xFF1E7A3D), Colors.white, Icons.check_circle_outline),
    };

    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      offset: visible ? Offset.zero : const Offset(0.2, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: BoxDecoration(color: background, boxShadow: EvaShadows.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.message.text,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close, size: 18, color: foreground),
                    onPressed: widget.onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
