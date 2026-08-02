import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/widget/modal/delete_customer.dart';
import 'package:acalapp/features/customer/widget/modal/open_customer.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const _actionButtonWidth = 180.0;
const _filterBarNarrowBreakpoint = 640.0;

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

  Future<void> _openForm({Customer? customer}) async {
    if (await openCustomer(context, customer: customer)) _load();
  }

  Future<void> _delete(Customer customer) async {
    if (await deleteCustomer(context, _service, customer)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < _filterBarNarrowBreakpoint;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(narrow ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Sócios',
              subtitle: 'Gerencie os sócios cadastrados.',
              action: SizedBox(
                width: _actionButtonWidth,
                child: FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Novo Sócio'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _CustomerFilterBar(onSearch: _load),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(narrow ? 16 : 24),
                  child: PagedListView<Customer>(
                    future: _future,
                    columns: const [
                      DataTableColumn('Nome', flex: 3, sortable: true),
                      DataTableColumn('Documento', flex: 2),
                      DataTableColumn('Nº Sócio', width: 90),
                      DataTableColumn('Votante', width: 90),
                      DataTableColumn('Ações', width: 88),
                    ],
                    emptyMessage: 'Nenhum sócio cadastrado.',
                    errorMessage: 'Erro ao carregar sócios',
                    onRetry: _load,
                    onPageChanged: _goToPage,
                    pageSize: _pageSize,
                    onPageSizeChanged: _changePageSize,
                    rowBuilder: (context, customer) => _CustomerRow(
                      customer: customer,
                      onEdit: () => _openForm(customer: customer),
                      onDelete: () => _delete(customer),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerFilterBar extends StatelessWidget {
  const _CustomerFilterBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _filterBarNarrowBreakpoint;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: narrow ? double.infinity : _actionButtonWidth,
                child: FilledButton.icon(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Consultar'),
                ),
              ),
            ),
          ],
        );
      },
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(customer.name, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 2,
            child: Text(customer.document, style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 90,
            child: Text('${customer.membershipNumber}', style: theme.textTheme.bodyMedium),
          ),
          SizedBox(
            width: 90,
            child: Icon(
              customer.voter ? Icons.check : Icons.close,
              size: 18,
              color: customer.voter ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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
