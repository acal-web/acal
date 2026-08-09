import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/widget/customer_filter_bar.dart';
import 'package:acalapp/features/customer/widget/modal/delete_customer.dart';
import 'package:acalapp/features/customer/widget/modal/open_customer.dart';
import 'package:acalapp/shared/widgets/bool_text.dart';
import 'package:acalapp/shared/widgets/document_text.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _service = CustomerService();
  late Future<PagedResult<Customer>> _future;
  int _page = 0;
  int _pageSize = 10;
  String? _filterName;
  String? _filterDocument;
  bool? _filterActive = true;
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<PagedResult<Customer>> _fetch() => _service.findAll(
    page: _page,
    size: _pageSize,
    name: _filterName,
    document: _filterDocument,
    active: _filterActive,
    sort: _sortColumn,
    sortAscending: _sortAscending,
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

  void _search({String? name, String? document, required bool? active}) => setState(() {
    _filterName = name;
    _filterDocument = document;
    _filterActive = active;
    _page = 0;
    _future = _fetch();
  });

  void _sort(String sortKey) => setState(() {
    _sortAscending = _sortColumn == sortKey ? !_sortAscending : true;
    _sortColumn = sortKey;
    _page = 0;
    _future = _fetch();
  });

  Future<void> _openForm({Customer? customer}) async {
    if (await openCustomer(context, customer: customer)) _load();
  }

  Future<void> _delete(Customer customer) async {
    if (await deleteCustomer(context, _service, customer)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;
    final padding = LayoutConfig.pagePadding(narrow);

    return Scaffold(
      body: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              subtitle: 'Sócios.',
            ),
            const Divider(),
            CustomerFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: PagedListView<Customer>(
                future: _future,
                columns: [
                  const DataTableColumn(
                    'Nome',
                    flex: 6,
                    sortable: true,
                    sortKey: 'name',
                  ),
                  const DataTableColumn(
                    'Documento',
                    flex: 2,
                    sortable: true,
                    sortKey: 'document',
                  ),
                  const DataTableColumn(
                    'Nº Sócio',
                    width: 90,
                    sortable: true,
                    sortKey: 'membership_number',
                  ),
                  const DataTableColumn(
                    'Votante',
                    width: 90,
                    sortable: true,
                    sortKey: 'voter',
                  ),
                  DataTableColumn('Ações', width: 140, headerWidget: AddButton(onPress: _openForm)),
                ],
                errorMessage: 'Erro ao carregar sócios',
                onRetry: _load,
                onPageChanged: _goToPage,
                pageSize: _pageSize,
                onPageSizeChanged: _changePageSize,
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onSort: _sort,
                rowBuilder: (context, customer) => _CustomerRow(
                  customer: customer,
                  onEdit: () => _openForm(customer: customer),
                  onDelete: () => _delete(customer),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    // Dims the customer's data (but not the row actions) so an inactive
    // sócio visibly reads as out of use, on top of the soft red row tint.
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: customer.active ? null : cs.onSurfaceVariant,
    );

    return ColoredBox(
      // Low alpha so the table's zebra striping still shows through.
      color: customer.active ? Colors.transparent : cs.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: Text(customer.name, style: style),
            ),
            Expanded(
              flex: 2,
              child: DocumentText(customer.document, style: style),
            ),
            SizedBox(
              width: 90,
              child: Text(
                customer.membershipNumber?.toString() ?? '—',
                style: style,
              ),
            ),
            SizedBox(
              width: 90,
              child: BoolText(customer.voter, style: style),
            ),
            SizedBox(
              width: 140,
              child: Center(child: RowActions(onEdit: onEdit, onDelete: onDelete)),
            ),
          ],
        ),
      ),
    );
  }
}
