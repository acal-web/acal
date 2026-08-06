import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/widget/connection_filter_bar.dart';
import 'package:acalapp/features/connections/widget/modal/delete_connection.dart';
import 'package:acalapp/features/connections/widget/modal/open_connection.dart';
import 'package:acalapp/shared/widgets/document_text.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const _actionButtonWidth = 180.0;
const _filterBarNarrowBreakpoint = 640.0;

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  final _service = ConnectionService();
  late Future<PagedResult<Connection>> _future;
  int _page = 0;
  int _pageSize = 10;
  String? _filterCustomerName;
  String? _filterCustomerDocument;
  String? _filterAddressName;
  String? _filterCategoryId;
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<PagedResult<Connection>> _fetch() => _service.findAll(
        page: _page,
        size: _pageSize,
        customerName: _filterCustomerName,
        customerDocument: _filterCustomerDocument,
        addressName: _filterAddressName,
        categoryId: _filterCategoryId,
        active: _filterActive,
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

  void _search(ConnectionFilters filters) => setState(() {
        _filterCustomerName = filters.customerName;
        _filterCustomerDocument = filters.customerDocument;
        _filterAddressName = filters.addressName;
        _filterCategoryId = filters.categoryId;
        _filterActive = filters.active;
        _page = 0;
        _future = _fetch();
      });

  Future<void> _openForm({Connection? connection}) async {
    if (await openConnection(context, connection: connection)) _load();
  }

  Future<void> _delete(Connection connection) async {
    if (await deleteConnection(context, _service, connection)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < _filterBarNarrowBreakpoint;

    final header = PageHeader(
      title: 'Ligações',
      subtitle: 'Gerencie as ligações de água.',
      action: SizedBox(
        width: _actionButtonWidth,
        child: FilledButton.icon(
          onPressed: _openForm,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova Ligação'),
        ),
      ),
    );

    final table = Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(narrow ? 12 : 16),
        child: PagedListView<Connection>(
          future: _future,
          columns: const [
            DataTableColumn('Sócio', flex: 3),
            DataTableColumn('Logradouro', flex: 3),
            DataTableColumn('Nº', width: 70),
            DataTableColumn('Categoria', flex: 2),
            DataTableColumn('Ativa', width: 70),
            DataTableColumn('Ações', width: 88),
          ],
          emptyMessage: 'Nenhuma ligação cadastrada.',
          errorMessage: 'Erro ao carregar ligações',
          onRetry: _load,
          onPageChanged: _goToPage,
          pageSize: _pageSize,
          onPageSizeChanged: _changePageSize,
          rowBuilder: (context, connection) => _ConnectionRow(
            connection: connection,
            onEdit: () => _openForm(connection: connection),
            onDelete: () => _delete(connection),
          ),
        ),
      ),
    );

    // ConnectionFilterBar has five stacked fields on narrow screens, tall
    // enough that header + filters alone can exceed a phone's viewport
    // height — scroll the page and give the table a fixed height instead of
    // forcing it into whatever (possibly negative) space an Expanded leaves.
    final body = narrow
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                ConnectionFilterBar(onSearch: _search),
                const SizedBox(height: 8),
                SizedBox(height: 480, child: table),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                ConnectionFilterBar(onSearch: _search),
                const SizedBox(height: 8),
                Expanded(child: table),
              ],
            ),
          );

    return Scaffold(body: body);
  }
}

class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({
    required this.connection,
    required this.onEdit,
    required this.onDelete,
  });

  final Connection connection;
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
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connection.customer?.name ?? '—', style: theme.textTheme.bodyMedium),
                if (connection.customer != null)
                  DocumentText(
                    connection.customer!.document,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(connection.address?.fullAddress ?? '—', style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 70,
            child: Text(
              connection.letter == null ? '${connection.number}' : '${connection.number} ${connection.letter}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(connection.category?.name ?? '—', style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 70,
            child: Icon(
              connection.active ? Icons.check : Icons.close,
              size: 18,
              color: connection.active ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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
