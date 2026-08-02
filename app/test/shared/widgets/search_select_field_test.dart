import 'package:acalapp/shared/widgets/search_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _fruits = ['Maçã', 'Banana', 'Manga', 'Uva'];

Future<List<String>> _search(String query) async {
  return _fruits.where((f) => f.toLowerCase().contains(query.toLowerCase())).toList();
}

Future<void> _pump(
  WidgetTester tester, {
  required GlobalKey<FormState> formKey,
  String? Function(String?)? validator,
  ValueChanged<String?>? onSelected,
  String? initialValue,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SearchSelectField<String>(
            label: 'Fruta',
            search: _search,
            labelBuilder: (s) => s,
            initialValue: initialValue,
            onSelected: onSelected ?? (_) {},
            validator: validator,
          ),
        ),
      ),
    ),
  );
}

Future<void> _settleSearch(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  testWidgets('shows matching options after the debounce', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey);

    await tester.enterText(find.byType(TextField), 'ma');
    await _settleSearch(tester);

    expect(find.text('Maçã'), findsOneWidget);
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);
  });

  testWidgets('tapping an option fills the field, reports it and hides the list', (tester) async {
    final formKey = GlobalKey<FormState>();
    String? selected;
    await _pump(tester, formKey: formKey, onSelected: (v) => selected = v);

    await tester.enterText(find.byType(TextField), 'ban');
    await _settleSearch(tester);

    await tester.tap(find.text('Banana'));
    await tester.pump();

    expect(selected, 'Banana');
    expect(find.byType(ListTile), findsNothing);

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, 'Banana');
  });

  testWidgets('shows the no-results message when a search returns nothing', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey);

    await tester.enterText(find.byType(TextField), 'xyz');
    await _settleSearch(tester);

    expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
  });

  testWidgets('fails required validation when nothing is selected', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey, validator: (v) => v == null ? 'Obrigatório' : null);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Obrigatório'), findsOneWidget);
  });

  testWidgets('passes validation once an option has been selected', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey, validator: (v) => v == null ? 'Obrigatório' : null);

    await tester.enterText(find.byType(TextField), 'uva');
    await _settleSearch(tester);
    await tester.tap(find.text('Uva'));
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
  });
}
