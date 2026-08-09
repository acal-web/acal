import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/widget/modal/delete_category.dart';
import 'package:acalapp/features/categories/widget/modal/open_category.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _service = CategoryService();
  late Future<PagedResult<Category>> _future;
  int _page = 0;
  int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _future = _service.findAll(page: _page, size: _pageSize);
  }

  void _load() => setState(() {
    _future = _service.findAll(page: _page, size: _pageSize);
  });

  void _goToPage(int page) => setState(() {
    _page = page;
    _future = _service.findAll(page: _page, size: _pageSize);
  });

  void _changePageSize(int size) => setState(() {
    _pageSize = size;
    _page = 0;
    _future = _service.findAll(page: _page, size: _pageSize);
  });

  Future<void> _openForm({Category? category}) async {
    if (await openCategory(context, category: category)) _load();
  }

  Future<void> _delete(Category category) async {
    if (await deleteCategory(context, _service, category)) _load();
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
            PageHeader(
              title: 'Categorias',
              subtitle: 'Gerencie as categorias de sócios cadastradas.',
              action: FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: _openForm,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Nova Categoria'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _CategoryFilterBar(onSearch: _load),
            const SizedBox(height: 8),
            Expanded(
              child: PagedListView<Category>(
                future: _future,
                columns: const [
                  DataTableColumn('Nome', flex: 5),
                  DataTableColumn('Hidrômetro', width: 100),
                  DataTableColumn('Valor Água', flex: 2),
                  DataTableColumn('Valor Societário', flex: 2),
                  DataTableColumn('Total', flex: 2),
                  DataTableColumn('Ações', width: 88),
                ],
                emptyMessage: 'Nenhuma categoria cadastrada.',
                errorMessage: 'Erro ao carregar categorias',
                onRetry: _load,
                onPageChanged: _goToPage,
                pageSize: _pageSize,
                onPageSizeChanged: _changePageSize,
                rowBuilder: (context, category) => _CategoryRow(
                  category: category,
                  onEdit: () => _openForm(category: category),
                  onDelete: () => _delete(category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < LayoutConfig.narrowBreakpoint;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: narrow ? double.infinity : null,
                child: FButton(
                  mainAxisSize: MainAxisSize.min,
                  onPress: onSearch,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 18),
                      SizedBox(width: 8),
                      Text('Consultar'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        spacing: columnSpacing,
        children: [
          Expanded(
            flex: 5,
            child: Text(category.fullName, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 100,
            child: Text(
              category.hasWaterMeter ? "Sim" : "Não",
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatBRL(category.waterPrice),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatBRL(category.membershipPrice),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatBRL(category.waterPrice + category.membershipPrice),
              style: theme.textTheme.bodyMedium?.copyWith(
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
    );
  }
}
