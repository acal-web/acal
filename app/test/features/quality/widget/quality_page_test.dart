import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/features/quality/presentation/quality_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

final _analysis = QualityAnalysis(
  id: 'qa-1',
  referenceDate: DateTime(2026, 8, 1),
  paramName: 'Turbidez',
  required: 5,
  analyzed: 3,
  compliant: 3,
);

class _FakeQualityAnalysisService extends QualityAnalysisService {
  _FakeQualityAnalysisService({List<QualityAnalysis>? analyses}) : analyses = analyses ?? [_analysis];

  List<QualityAnalysis> analyses;
  String? deletedId;

  @override
  Future<PagedResult<QualityAnalysis>> findAll({
    int page = 0,
    int size = 10,
    int? year,
    int? month,
    String? sort,
    bool sortAscending = true,
  }) async =>
      PagedResult(
        data: analyses,
        pagination: Pagination(number: 0, totalPages: 1, totalElements: analyses.length, size: size, first: true, last: true),
      );

  @override
  Future<void> delete(String id) async {
    deletedId = id;
    analyses = analyses.where((a) => a.id != id).toList();
  }
}

Future<void> _pump(WidgetTester tester, QualityAnalysisService service) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => FTheme(
      data: fThemeLight,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: QualityPage(qualityAnalysisService: service),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists quality analyses with required/analyzed/compliant', (tester) async {
    await _pump(tester, _FakeQualityAnalysisService());

    expect(find.text('Turbidez'), findsOneWidget);
    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);
  });

  testWidgets('shows an empty message when there are no analyses', (tester) async {
    await _pump(tester, _FakeQualityAnalysisService(analyses: []));

    expect(find.text('Nenhuma análise cadastrada.'), findsOneWidget);
  });

  testWidgets('deleting a row confirms and removes it from the list', (tester) async {
    final service = _FakeQualityAnalysisService();
    await _pump(tester, service);

    await tester.tap(find.byKey(const Key('row_action_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete_confirm_button')));
    await tester.pumpAndSettle();

    expect(service.deletedId, 'qa-1');
    expect(find.text('Nenhuma análise cadastrada.'), findsOneWidget);
  });
}
