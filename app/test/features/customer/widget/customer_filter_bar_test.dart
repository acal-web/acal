import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/customer/widget/customer_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

Future<void> _pump(
  WidgetTester tester,
  void Function({String? name, String? document, required bool? active}) onSearch,
) async {
  tester.view.physicalSize = const Size(1400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => FTheme(
        data: fThemeLight,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
      home: Scaffold(body: CustomerFilterBar(onSearch: onSearch)),
    ),
  );

  // The filter section starts collapsed — expand it and let the reveal
  // animation finish so the fields are hit-testable for the rest of the test.
  await tester.tap(find.text('Filtros'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reports the trimmed name and raw document digits on search', (tester) async {
    String? capturedName;
    String? capturedDocument;

    await _pump(tester, ({name, document, required active}) {
      capturedName = name;
      capturedDocument = document;
    });

    await tester.enterText(find.byType(TextField).at(0), '  Fulano  ');
    await tester.enterText(find.byType(TextField).at(1), '12345678909');
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(capturedName, 'Fulano');
    expect(capturedDocument, '12345678909');
  });

  testWidgets('toggling the document icon switches between CPF and CNPJ labels', (tester) async {
    await _pump(tester, ({name, document, required active}) {});

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Documento (CPF):'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.business), findsOneWidget);
    expect(find.text('Documento (CNPJ):'), findsOneWidget);
  });

  testWidgets('clearing resets both fields, the document kind, and reports no filter', (tester) async {
    var searchCalls = 0;
    String? capturedName = 'unset';
    String? capturedDocument = 'unset';

    await _pump(tester, ({name, document, required active}) {
      searchCalls++;
      capturedName = name;
      capturedDocument = document;
    });

    await tester.enterText(find.byType(TextField).at(0), 'Fulano');
    await tester.enterText(find.byType(TextField).at(1), '11222333000181');
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.business), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(searchCalls, 1);
    expect(capturedName, isNull);
    expect(capturedDocument, isNull);
    expect(find.text('Fulano'), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Documento (CPF):'), findsOneWidget);
  });
}
