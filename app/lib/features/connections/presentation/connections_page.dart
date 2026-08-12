import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/widget/connection_filter_bar.dart';
import 'package:acalapp/features/connections/widget/modal/delete_connection.dart';
import 'package:acalapp/features/connections/widget/modal/open_connection.dart';
import 'package:acalapp/shared/widgets/document_text.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const columnSpacing = 12.0;

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final _service = ConnectionService();
  final _scrollController = ScrollController();
  final List<Connection> _allConnections = [];

  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  String? _filterCustomerName;
  String? _filterCustomerDocument;
  String? _filterAddressName;
  String? _filterCategoryId;
  bool? _filterActive;
  String? _errorMessage;
  String _sortBy = 'customer_name';
  String _sortDirection = 'asc';

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
    _allConnections.clear();
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
        customerName: _filterCustomerName,
        customerDocument: _filterCustomerDocument,
        addressName: _filterAddressName,
        categoryId: _filterCategoryId,
        active: _filterActive,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      setState(() {
        _allConnections.addAll(result.data);
        _totalCount = result.pagination.totalElements;
        _hasMorePages = result.pagination.nextPage != null;
        _currentPage++;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar ligações';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _search(ConnectionFilters filters) async {
    _filterCustomerName = filters.customerName;
    _filterCustomerDocument = filters.customerDocument;
    _filterAddressName = filters.addressName;
    _filterCategoryId = filters.categoryId;
    _filterActive = filters.active;
    await _loadFirstPage();
  }

  void _onHeaderSort(String field) async {
    if (_sortBy == field) {
      _sortDirection = _sortDirection == 'asc' ? 'desc' : 'asc';
    } else {
      _sortBy = field;
      _sortDirection = 'asc';
    }
    await _loadFirstPage();
  }

  Future<void> _openForm({Connection? connection}) async {
    if (await openConnection(context, connection: connection)) {
      await _loadFirstPage();
    }
  }

  Future<void> _delete(Connection connection) async {
    if (await deleteConnection(context, _service, connection)) {
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
            const PageHeader(subtitle: 'Gerencie as ligações de água.'),
            const Divider(),
            ConnectionFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allConnections.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma ligação cadastrada.'))
                      : _buildTableWithInfiniteScroll(),
            ),
            if (_allConnections.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mostrando ${_allConnections.length} de $_totalCount registros',
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
        _TableHeader(
          onAddPress: () => _openForm(),
          onSort: _onHeaderSort,
          currentSortBy: _sortBy,
          currentSortDirection: _sortDirection,
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: _allConnections.length + (_isLoading ? 1 : 0),
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == _allConnections.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final connection = _allConnections[index];
              final isEven = index.isEven;

              return _ConnectionRow(
                connection: connection,
                onEdit: () => _openForm(connection: connection),
                onDelete: () => _delete(connection),
                isEven: isEven,
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
  final Function(String) onSort;
  final String currentSortBy;
  final String currentSortDirection;

  const _TableHeader({
    required this.onAddPress,
    required this.onSort,
    required this.currentSortBy,
    required this.currentSortDirection,
  });

  Widget _buildSortableHeader(
    BuildContext context,
    String label,
    String field,
    TextStyle? headerStyle,
  ) {
    final isSorted = currentSortBy == field;
    final isAsc = currentSortDirection == 'asc';

    return GestureDetector(
      onTap: () => onSort(field),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: headerStyle),
          if (isSorted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                isAsc ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
            ),
        ],
      ),
    );
  }

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
            flex: 3,
            child: _buildSortableHeader(context, 'Sócio', 'customer_name', headerStyle),
          ),
          Expanded(
            flex: 4,
            child: _buildSortableHeader(context, 'Localização', 'address_name', headerStyle),
          ),
          Expanded(
            flex: 2,
            child: _buildSortableHeader(context, 'Categoria', 'category_name', headerStyle),
          ),
          SizedBox(
            width: 70,
            child: Center(child: Text('Ativa', style: headerStyle)),
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

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.connection,
    required this.onEdit,
    required this.onDelete,
    this.isEven = false,
  });

  final Connection connection;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isEven;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = connection.active
        ? (isEven
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainer.withValues(alpha: 0.4))
        : (isEven
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.2) : theme.colorScheme.errorContainer.withValues(alpha: 0.4));
    final bodyMedium = theme.textTheme.bodyMedium;
    final bodySmall = theme.textTheme.bodySmall;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final primary = theme.colorScheme.primary;
    final textColor = connection.active ? null : onSurfaceVariant;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.customer?.name ?? '—',
                    style: bodyMedium?.copyWith(color: textColor),
                  ),
                  if (connection.customer != null)
                    DocumentText(
                      connection.customer!.document,
                      style: bodySmall?.copyWith(color: onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                connection.fullLocation,
                style: bodyMedium?.copyWith(color: textColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                connection.category?.name ?? '—',
                style: bodyMedium?.copyWith(color: textColor),
              ),
            ),
            SizedBox(
              width: 70,
              child: Icon(
                connection.active ? Icons.check : Icons.close,
                size: 18,
                color: connection.active ? primary : onSurfaceVariant,
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
