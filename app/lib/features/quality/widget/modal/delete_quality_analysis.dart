import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/delete_confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> deleteQualityAnalysis(
  BuildContext context,
  QualityAnalysisService service,
  QualityAnalysis analysis,
) async {
  final confirmed = await showDeleteConfirmDialog(
    context: context,
    title: 'Excluir análise',
    message:
        'Deseja excluir a análise de "${analysis.paramName}" referente a ${formatMonthReference(analysis.referenceDate)}?',
  );
  if (!confirmed) return false;
  await service.delete(analysis.id!);
  return true;
}
