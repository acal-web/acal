import 'package:acalapp/features/elections/presentation/elections_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders without error', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ElectionsPage()));

    expect(find.text('Eleição'), findsOneWidget);
  });
}
