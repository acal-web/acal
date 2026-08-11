import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_filter_bar.dart';
import 'package:acalapp/features/addresses/widget/modal%20/delete_address.dart';
import 'package:acalapp/features/addresses/widget/modal%20/open_address.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const columnSpacing = 12.0;

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  final _service = AddressService();
  final _scrollController = ScrollController();
  final List<Address> _allAddresses = [];

  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  String? _filterName;
  String? _filterKind;
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
    _allAddresses.clear();
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
        kind: _filterKind,
        active: _filterActive,
        sort: 'kind,name',
        sortAscending: true,
      );

      setState(() {
        _allAddresses.addAll(result.data);
        _totalCount = result.pagination.totalElements;
        _hasMorePages = result.pagination.nextPage != null;
        _currentPage++;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar endereços';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _search({String? name, String? kind, required bool? active}) async {
    _filterName = name;
    _filterKind = kind;
    _filterActive = active;
    await _loadFirstPage();
  }

  Future<void> _openForm({Address? address}) async {
    if (await openAddress(context, address: address)) {
      await _loadFirstPage();
    }
  }

  Future<void> _delete(Address address) async {
    if (await deleteAddress(context, _service, address)) {
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
            const PageHeader(subtitle: 'Gerencie os endereços cadastrados.'),
            const Divider(),
            AddressFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allAddresses.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhum endereço cadastrado.'))
                      : _buildTableWithInfiniteScroll(),
            ),
            if (_allAddresses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mostrando ${_allAddresses.length} de $_totalCount registros',
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
            itemCount: _allAddresses.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allAddresses.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              final address = _allAddresses[index];
              final isEven = index.isEven;

              return Column(
                children: [
                  Container(
                    color: isEven
                        ? Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest
                        : Colors.transparent,
                    child: _AddressRow(
                      address: address,
                      onEdit: () => _openForm(address: address),
                      onDelete: () => _delete(address),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: columnSpacing,
          children: [
            SizedBox(
              width: 120,
              child: Text('Tipo', style: headerStyle),
            ),
            Expanded(
              flex: 3,
              child: Text('Nome', style: headerStyle),
            ),
            SizedBox(
              width: 88,
              child: Center(
                child: AddButton(onPress: onAddPress),
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
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: address.active ? null : cs.onSurfaceVariant,
    );

    return ColoredBox(
      color: address.active ? Colors.transparent : cs.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: columnSpacing,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  address.kind,
                  style: style,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  address.name,
                  style: style,
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
      ),
    );
  }
}
