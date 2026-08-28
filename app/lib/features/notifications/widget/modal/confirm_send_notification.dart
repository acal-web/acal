import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Confirmation before firing a broadcast push notification — this is a
/// mass, irreversible action, so it gets the same "are you sure" gate as a
/// destructive delete, showing exactly how many sócios will be reached.
Future<bool> showConfirmSendNotificationDialog({
  required BuildContext context,
  required int recipientCount,
}) async {
  final isNarrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;
  final message = recipientCount == 1
      ? 'Esta notificação será enviada para 1 sócio. Deseja continuar?'
      : 'Esta notificação será enviada para $recipientCount sócios. Deseja continuar?';

  if (isNarrow) {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: _buildContent(context, message),
      ),
    );
    return confirmed == true;
  }

  final confirmed = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => FDialog(
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: _buildContent(context, message),
        ),
      ),
    ),
  );
  return confirmed == true;
}

Widget _buildContent(BuildContext context, String message) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Enviar notificação', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Text(message),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FButton(
            variant: FButtonVariant.ghost,
            onPress: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: 'confirm-send-notification-button',
            child: FButton(
              onPress: () => Navigator.of(context).pop(true),
              child: const Text('Enviar'),
            ),
          ),
        ],
      ),
    ],
  );
}
