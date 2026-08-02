import 'package:acalapp/core/theme/light_theme.dart';
import 'package:acalapp/features/customer/widget/customer_form_page.dart';
import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      home: const Scaffold(body: CustomerFormPage()),
    ),
  );
}

// Field order in CustomerFormPage: Nome, Documento, Número de Sócio.
Finder _documentField() => find.byType(TextFormField).at(1);

void main() {
  testWidgets('defaults the document field to the CPF (person) icon and mask', (tester) async {
    await _pump(tester);

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.text('Documento (CPF)'), findsOneWidget);

    await tester.enterText(_documentField(), '12345678909');
    await tester.pump();

    expect(find.text('123.456.789-09'), findsOneWidget);
  });

  testWidgets('tapping the toggle icon switches to CNPJ (company) and re-masks the same digits', (tester) async {
    await _pump(tester);

    await tester.enterText(_documentField(), '12345678909');
    await tester.pump();
    expect(find.text('123.456.789-09'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();

    expect(find.byIcon(Icons.business), findsOneWidget);
    expect(find.text('Documento (CNPJ)'), findsOneWidget);
    expect(find.text(maskDocument('12345678909', DocumentKind.cnpj)), findsOneWidget);
  });

  testWidgets('accepts a full CNPJ once switched to company mode', (tester) async {
    await _pump(tester);

    await tester.tap(find.byIcon(Icons.person));
    await tester.pump();

    await tester.enterText(_documentField(), '11222333000181');
    await tester.pump();

    expect(find.text('11.222.333/0001-81'), findsOneWidget);
  });

  testWidgets('rejects a CPF with an invalid check digit', (tester) async {
    await _pump(tester);

    await tester.enterText(_documentField(), '11144477736');
    await tester.pump();

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isFalse);
    await tester.pump();

    expect(find.text('CPF inválido'), findsOneWidget);
  });
}
