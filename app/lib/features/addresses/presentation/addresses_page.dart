import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/modal%20/delete_address.dart';
import 'package:acalapp/features/addresses/widget/modal%20/open_address.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final _service = AddressService();
  late Future<PagedResult<Address>> _future;
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

  Future<void> _openForm({Address? address}) async {
    if (await openAddress(context, address: address)) _load();
  }

  Future<void> _delete(Address address) async {
    if (await deleteAddress(context, _service, address)) _load();
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
              title: 'Logradouros',
              subtitle: 'Gerencie os endereços cadastrados.',
              action: FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: _openForm,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Novo Endereço'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _AddressFilterBar(onSearch: _load),
            const SizedBox(height: 8),
            Expanded(
              child: PagedListView<Address>(
                future: _future,
                columns: const [
                  DataTableColumn('Logradouro', flex: 2, sortable: true),
                  DataTableColumn('Ações', width: 88),
                ],
                emptyMessage: 'Nenhum endereço cadastrado.',
                errorMessage: 'Erro ao carregar endereços',
                onRetry: _load,
                onPageChanged: _goToPage,
                pageSize: _pageSize,
                onPageSizeChanged: _changePageSize,
                rowBuilder: (context, address) => _AddressRow(
                  address: address,
                  onEdit: () => _openForm(address: address),
                  onDelete: () => _delete(address),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFilterBar extends StatelessWidget {
  const _AddressFilterBar({required this.onSearch});

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

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(address.fullAddress, style: theme.textTheme.bodyMedium),
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
