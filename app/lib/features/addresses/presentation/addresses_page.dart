import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_filter_bar.dart';
import 'package:acalapp/features/addresses/widget/modal%20/delete_address.dart';
import 'package:acalapp/features/addresses/widget/modal%20/open_address.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart';
import 'package:acalapp/shared/widgets/table/paged_list_view.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

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
  String? _filterName;
  String? _filterKind;
  bool? _filterActive = true;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<PagedResult<Address>> _fetch() => _service.findAll(
    page: _page,
    size: _pageSize,
    name: _filterName,
    kind: _filterKind,
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

  void _search({String? name, String? kind, required bool? active}) => setState(() {
    _filterName = name;
    _filterKind = kind;
    _filterActive = active;
    _page = 0;
    _future = _fetch();
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
            const PageHeader(subtitle: 'Gerencie os endereços cadastrados.'),
            const Divider(),
            AddressFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: PagedListView<Address>(
                future: _future,
                columns: [
                  const DataTableColumn('Logradouro', flex: 2),
                  DataTableColumn('Ações', width: 88, headerWidget: AddButton(onPress: _openForm)),
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
