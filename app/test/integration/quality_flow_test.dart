// See test/integration/categories_flow_test.dart for what this tier covers
// and why it's plain flutter_test rather than package:integration_test.
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/core/theme/app_theme.dart';
import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/features/quality/presentation/quality_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

class _FakeQualityAnalysisService extends QualityAnalysisService {
  final List<QualityAnalysis> _analyses = [];
  int _nextId = 1;

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
        data: _analyses,
        pagination: Pagination(number: 0, totalPages: 1, totalElements: _analyses.length, size: size, first: true, last: true),
      );

  @override
  Future<QualityAnalysis> create(QualityAnalysis analysis) async {
    final saved = QualityAnalysis(
      id: 'qa-${_nextId++}',
      referenceDate: analysis.referenceDate,
      paramName: analysis.paramName,
      required: analysis.required,
      analyzed: analysis.analyzed,
      compliant: analysis.compliant,
    );
    _analyses.add(saved);
    return saved;
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
  testWidgets('creating a period saves one analysis per parameter with the fake service', (tester) async {
    final service = _FakeQualityAnalysisService();
    // Seed an anchor so the wide layout's header (and "Adicionar" button)
    // renders before the create flow runs.
    await service.create(QualityAnalysis(referenceDate: DateTime(2026, 7, 1), paramName: 'Turbidez', required: 5, analyzed: 3, compliant: 3));
    await _pump(tester, service);

    expect(find.text('Mostrando 1 de 1 registros'), findsOneWidget);

    // Every parameter's fields default to '0', which already satisfies the
    // "required" validation, so saving with no edits creates one analysis
    // per entry in qualityAnalysisParamNames (5) in a single form submit.
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('form_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Análise criada com sucesso.'), findsOneWidget);
    expect(find.text('Mostrando 6 de 6 registros'), findsOneWidget);
    expect(service._analyses.where((a) => a.paramName == 'Cloro Residual'), hasLength(1));
    expect(service._analyses.where((a) => a.paramName == 'Escherichia Coli'), hasLength(1));
  });
}
