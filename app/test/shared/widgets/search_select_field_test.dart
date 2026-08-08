import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/shared/widgets/search_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

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
      builder: (context, child) => FTheme(
        data: fThemeLight,
        child: FToaster(child: FTooltipGroup(child: child!)),
      ),
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

// Opens the popover (tap + settle the open animation) and types into its
// inner search field — the outer field is a read-only display trigger, the
// second TextField that appears once the popover is open is the real input.
Future<void> _search_(WidgetTester tester, String query) async {
  await tester.tap(find.byType(TextField));
  await tester.pump();
  await tester.enterText(find.byType(TextField).last, query);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

void main() {
  testWidgets('shows matching options after the debounce', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey);

    await _search_(tester, 'ma');

    expect(find.text('Maçã'), findsOneWidget);
    expect(find.text('Manga'), findsOneWidget);
    expect(find.text('Banana'), findsNothing);
  });

  testWidgets('tapping an option fills the field, reports it and hides the list', (tester) async {
    final formKey = GlobalKey<FormState>();
    String? selected;
    await _pump(tester, formKey: formKey, onSelected: (v) => selected = v);

    await _search_(tester, 'ban');

    await tester.tap(find.text('Banana'));
    await tester.pumpAndSettle();

    expect(selected, 'Banana');
    // The popover's inner search field is gone — only the outer display field remains.
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Banana');
  });

  testWidgets('shows the no-results message when a search returns nothing', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey);

    await _search_(tester, 'xyz');

    expect(find.text('Nenhum resultado encontrado'), findsOneWidget);
  });

  testWidgets('fails required validation when nothing is selected', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey, validator: (v) => v == null ? 'Obrigatório' : null);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();

    expect(find.text('Obrigatório'), findsOneWidget);
  });

  testWidgets('passes validation once an option has been selected', (tester) async {
    final formKey = GlobalKey<FormState>();
    await _pump(tester, formKey: formKey, validator: (v) => v == null ? 'Obrigatório' : null);

    await _search_(tester, 'uva');
    await tester.tap(find.text('Uva'));
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isTrue);
  });
}
