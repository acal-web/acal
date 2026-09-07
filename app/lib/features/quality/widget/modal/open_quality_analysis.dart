import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/features/quality/widget/quality_analysis_form_page.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> openQualityAnalysis(
  BuildContext context, {
  QualityAnalysis? analysis,
  QualityAnalysisService? analysisService,
}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => QualityAnalysisFormPage(analysis: analysis, analysisService: analysisService),
  );
  return saved == true;
}
