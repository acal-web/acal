import 'package:acalapp/features/documentation/presentation/documentation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders without error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DocumentationPage()));

    expect(find.text('Documentação'), findsOneWidget);
  });
}
