import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/quality/data/quality_analysis_service.dart';
import 'package:acalapp/features/quality/domain/quality_analysis.dart';
import 'package:acalapp/features/quality/widget/modal/delete_quality_analysis.dart';
import 'package:acalapp/features/quality/widget/modal/open_quality_analysis.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/collapsible_filter_panel.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const columnSpacing = 12.0;

class QualityPage extends StatefulWidget {
  const QualityPage({super.key});

  @override
  State<QualityPage> createState() => _QualityPageState();
}

class _QualityPageState extends State<QualityPage> {
  final _service = QualityAnalysisService();
  final _scrollController = ScrollController();
  final List<QualityAnalysis> _allAnalyses = [];

  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  MonthYear? _period;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    _allAnalyses.clear();
    _currentPage = 0;
    _hasMorePages = true;
    _errorMessage = null;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMorePages) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _service.findAll(
        page: _currentPage,
        size: _pageSize,
        year: _period?.year,
        month: _period?.month,
        sort: 'reference_date',
        sortAscending: false,
      );

      if (mounted) {
        setState(() {
          _allAnalyses.addAll(result.data);
          _totalCount = result.pagination.totalElements;
          _hasMorePages = result.pagination.nextPage != null;
          _currentPage++;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar análises';
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _changePeriod(MonthYear? period) async {
    _period = period;
    await _loadFirstPage();
  }

  Future<void> _openForm({QualityAnalysis? analysis}) async {
    if (await openQualityAnalysis(context, analysis: analysis)) {
      await _loadFirstPage();
    }
  }

  Future<void> _delete(QualityAnalysis analysis) async {
    if (await deleteQualityAnalysis(context, _service, analysis)) {
      await _loadFirstPage();
    }
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
            const PageHeader(subtitle: 'Resultados das medições laboratoriais de qualidade.'),
            const Divider(),
            CollapsibleFilterPanel(
              builder: (context, narrow) => Row(
                children: [
                  Text(
                    'Filtrar por Período',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(width: 12),
                  PeriodFilterButton(
                    period: _period,
                    onChanged: _changePeriod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allAnalyses.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma análise cadastrada.'))
                      : _buildTableWithInfiniteScroll(),
            ),
            if (_allAnalyses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mostrando ${_allAnalyses.length} de $_totalCount registros',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFirstPage,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableWithInfiniteScroll() {
    return Column(
      children: [
        _TableHeader(onAddPress: () => _openForm()),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _allAnalyses.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allAnalyses.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final analysis = _allAnalyses[index];
              final isEven = index.isEven;

              return Column(
                children: [
                  _QualityAnalysisRow(
                    analysis: analysis,
                    onEdit: () => _openForm(analysis: analysis),
                    onDelete: () => _delete(analysis),
                    isEven: isEven,
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final VoidCallback onAddPress;

  const _TableHeader({required this.onAddPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        spacing: columnSpacing,
        children: [
          SizedBox(
            width: 100,
            child: Text('Referência', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Parâmetro', style: headerStyle),
          ),
          SizedBox(
            width: 80,
            child: Text('Exigido', style: headerStyle),
          ),
          SizedBox(
            width: 80,
            child: Text('Analisado', style: headerStyle),
          ),
          SizedBox(
            width: 80,
            child: Text('Conformidade', style: headerStyle),
          ),
          SizedBox(
            width: 88,
            child: Center(
              child: AddButton(onPress: onAddPress),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityAnalysisRow extends StatelessWidget {
  const _QualityAnalysisRow({
    required this.analysis,
    required this.onEdit,
    required this.onDelete,
    this.isEven = false,
  });

  final QualityAnalysis analysis;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurface,
    );

    return ColoredBox(
      color: isEven ? cs.surfaceContainerLowest : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                formatMonthReference(analysis.referenceDate),
                style: style,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                analysis.paramName,
                style: style,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${analysis.required}',
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${analysis.analyzed}',
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 80,
              child: Text(
                '${analysis.compliant}',
                style: style,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: 88,
              child: Center(
                child: RowActions(onEdit: onEdit, onDelete: onDelete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
