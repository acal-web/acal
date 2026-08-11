import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/widget/category_filter_bar.dart';
import 'package:acalapp/features/categories/widget/modal/delete_category.dart';
import 'package:acalapp/features/categories/widget/modal/open_category.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const columnSpacing = 12.0;

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _service = CategoryService();
  final _scrollController = ScrollController();
  final List<Category> _allCategories = [];

  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  String? _filterName;
  bool? _filterActive = true;
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
    _allCategories.clear();
    _currentPage = 0;
    _hasMorePages = true;
    _errorMessage = null;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() => _isLoading = true);

    try {
      final result = await _service.findAll(
        page: _currentPage,
        size: _pageSize,
        name: _filterName,
        active: _filterActive,
        sort: 'group,name',
        sortAscending: true,
      );

      setState(() {
        _allCategories.addAll(result.data);
        _totalCount = result.pagination.totalElements;
        _hasMorePages = result.pagination.nextPage != null;
        _currentPage++;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar categorias';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _search({String? name, required bool? active}) async {
    _filterName = name;
    _filterActive = active;
    await _loadFirstPage();
  }

  Future<void> _openForm({Category? category}) async {
    if (await openCategory(context, category: category)) {
      await _loadFirstPage();
    }
  }

  Future<void> _delete(Category category) async {
    if (await deleteCategory(context, _service, category)) {
      await _loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow =
        MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(subtitle: 'Gerencie as categorias de sócios cadastradas.'),
            const Divider(),
            CategoryFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allCategories.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma categoria cadastrada.'))
                      : _buildTableWithInfiniteScroll(),
            ),
            if (_allCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mostrando ${_allCategories.length} de $_totalCount registros',
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
            itemCount: _allCategories.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allCategories.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final category = _allCategories[index];
              final isEven = index.isEven;

              return Column(
                children: [
                  Container(
                    color: isEven
                        ? Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest
                        : Colors.transparent,
                    child: _CategoryRow(
                      category: category,
                      onEdit: () => _openForm(category: category),
                      onDelete: () => _delete(category),
                    ),
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: category.active ? null : cs.onSurfaceVariant,
    );

    return ColoredBox(
      color: category.active ? Colors.transparent : cs.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            Expanded(
              flex: 5,
              child: Text(category.fullName, style: style),
            ),
            SizedBox(
              width: 100,
              child: Text(
                category.hasWaterMeter ? "Sim" : "Não",
                style: style,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatBRL(category.waterPrice),
                style: style,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatBRL(category.membershipPrice),
                style: style,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatBRL(category.waterPrice + category.membershipPrice),
                style: style?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 88,
              child: RowActions(onEdit: onEdit, onDelete: onDelete),
            ),
          ],
        ),
      ),
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
          Expanded(
            flex: 5,
            child: Text('Nome', style: headerStyle),
          ),
          SizedBox(
            width: 100,
            child: Text('Hidrômetro', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Valor Água', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Valor Societário', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Total', style: headerStyle),
          ),
          SizedBox(
            width: 88,
            child: AddButton(onPress: onAddPress),
          ),
        ],
      ),
    );
  }
}
