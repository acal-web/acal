import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/notifications/widget/modal/confirm_send_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _Result {
  bool? value;
}

Future<_Result> _pump(WidgetTester tester, int recipientCount) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final result = _Result();
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(data: fThemeLight, child: child!),
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result.value = await showConfirmSendNotificationDialog(context: context, recipientCount: recipientCount);
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('uses singular wording for a single recipient', (tester) async {
    await _pump(tester, 1);

    expect(find.text('Esta notificação será enviada para 1 sócio. Deseja continuar?'), findsOneWidget);
  });

  testWidgets('uses plural wording for multiple recipients', (tester) async {
    await _pump(tester, 42);

    expect(find.text('Esta notificação será enviada para 42 sócios. Deseja continuar?'), findsOneWidget);
  });

  testWidgets('cancelling resolves to false', (tester) async {
    final result = await _pump(tester, 5);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result.value, isFalse);
    expect(find.text('Enviar notificação'), findsNothing);
  });

  testWidgets('confirming resolves to true', (tester) async {
    final result = await _pump(tester, 5);

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(result.value, isTrue);
    expect(find.text('Enviar notificação'), findsNothing);
  });
}
