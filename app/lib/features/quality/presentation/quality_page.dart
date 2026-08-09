import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/features/quality/widget/modal/delete_quality_analysis.dart';
import 'package:acalapp/features/quality/widget/modal/open_quality_analysis.dart';
import 'package:acalapp/features/quality/widget/quality_period_filter_button.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class QualityPage extends StatefulWidget {
  const QualityPage({super.key});

  @override
  State<QualityPage> createState() => _QualityPageState();
}

class _QualityPageState extends State<QualityPage> {
  final _service = QualityAnalysisService();
  late Future<PagedResult<QualityAnalysis>> _future;
  int _page = 0;
  int _pageSize = 10;
  QualityPeriod? _period;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<PagedResult<QualityAnalysis>> _fetch() => _service.findAll(
    page: _page,
    size: _pageSize,
    year: _period?.year,
    month: _period?.month,
  );

  void _load() => setState(() {
    _future = _fetch();
  });

  void _goToPage(int page) => setState(() {
    _page = page;
    _future = _fetch();
  });

  void _changePageSize(int size) => setState(() {
    _pageSize = size;
    _page = 0;
    _future = _fetch();
  });

  void _changePeriod(QualityPeriod? period) => setState(() {
    _period = period;
    _page = 0;
    _future = _fetch();
  });

  Future<void> _openForm({QualityAnalysis? analysis}) async {
    if (await openQualityAnalysis(context, analysis: analysis)) _load();
  }

  Future<void> _delete(QualityAnalysis analysis) async {
    if (await deleteQualityAnalysis(context, _service, analysis)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Análise de Água',
              subtitle: 'Resultados das medições laboratoriais de qualidade.',
              action: FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: _openForm,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Adicionar Análise'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Filtrar por Período',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 12),
                QualityPeriodFilterButton(
                  period: _period,
                  onChanged: _changePeriod,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PagedListView<QualityAnalysis>(
                future: _future,
                columns: const [
                  DataTableColumn('Referência', flex: 2),
                  DataTableColumn('Parâmetro', flex: 3),
                  DataTableColumn('Exigido', flex: 2),
                  DataTableColumn('Analisado', flex: 2),
                  DataTableColumn('Conformidade', flex: 2),
                  DataTableColumn('Ações', width: 88),
                ],
                emptyMessage: 'Nenhuma análise cadastrada.',
                errorMessage: 'Erro ao carregar análises',
                onRetry: _load,
                onPageChanged: _goToPage,
                pageSize: _pageSize,
                onPageSizeChanged: _changePageSize,
                rowBuilder: (context, analysis) => _QualityAnalysisRow(
                  analysis: analysis,
                  onEdit: () => _openForm(analysis: analysis),
                  onDelete: () => _delete(analysis),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualityAnalysisRow extends StatelessWidget {
  const _QualityAnalysisRow({
    required this.analysis,
    required this.onEdit,
    required this.onDelete,
  });

  final QualityAnalysis analysis;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: columnSpacing,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              formatMonthReference(analysis.referenceDate),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(analysis.paramName, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${analysis.required}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${analysis.analyzed}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${analysis.compliant}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SizedBox(
            width: 88,
            child: RowActions(onEdit: onEdit, onDelete: onDelete),
          ),
        ],
      ),
    );
  }
}
