import 'dart:async';

import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_filter_bar.dart';
import 'package:acalapp/features/addresses/widget/modal/delete_address.dart';
import 'package:acalapp/features/addresses/widget/modal/open_address.dart';
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
  bool? _filterActive = true;
  String? _errorMessage;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _service.findAll(
        page: _currentPage,
        size: _pageSize,
        name: _filterName,
        active: _filterActive,
        sort: 'name',
        sortAscending: true,
      );

      if (mounted) {
        setState(() {
          _allAddresses.addAll(result.data);
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
          _errorMessage = 'Erro ao carregar endereços';
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

  void _search({String? name, required bool? active}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        _filterName = name;
        _filterActive = active;
        await _loadFirstPage();
      }
    });
  }

  Future<void> _openForm({Address? address, bool readOnly = false}) async {
    if (await openAddress(context, address: address, readOnly: readOnly)) {
      await _loadFirstPage();
    }
  }

  Future<void> _delete(Address address) async {
    if (await deleteAddress(context, _service, address)) {
      await _loadFirstPage();
    }
  }

  Future<void> _reactivate(Address address) async {
    try {
      await _service.restore(address.id!);
      await _loadFirstPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao reativar endereço')),
        );
      }
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
            PageHeader(
              subtitle: 'Gerencie os endereços cadastrados.',
              action: narrow ? AddButton(onPress: () => _openForm()) : null,
            ),
            const Divider(),
            AddressFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allAddresses.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhum endereço cadastrado.'))
                      : _buildTableWithInfiniteScroll(narrow),
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

  Widget _buildTableWithInfiniteScroll(bool narrow) {
    return Column(
      children: [
        if (!narrow) ...[
          _TableHeader(onAddPress: () => _openForm()),
          const Divider(height: 1),
        ],
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            itemCount: _allAddresses.length + (_isLoading ? 1 : 0),
            separatorBuilder: (_, _) =>
                narrow ? const SizedBox(height: 8) : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == _allAddresses.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final address = _allAddresses[index];
              final isEven = index.isEven;

              return narrow
                  ? _AddressCard(
                      address: address,
                      onEdit: () => _openForm(address: address),
                      onDelete: () => _delete(address),
                      onView: () => _openForm(address: address, readOnly: true),
                      onReactivate: () => _reactivate(address),
                    )
                  : _AddressRow(
                      address: address,
                      onEdit: () => _openForm(address: address),
                      onDelete: () => _delete(address),
                      onView: () => _openForm(address: address, readOnly: true),
                      onReactivate: () => _reactivate(address),
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
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.onReactivate,
    this.isEven = false,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onView;
  final VoidCallback? onReactivate;
  final bool isEven;

  static Color _getBackgroundColor(ColorScheme colorScheme, bool isEven) =>
      isEven
          ? colorScheme.surfaceContainer.withValues(alpha: 0.2)
          : colorScheme.surfaceContainer.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: address.active ? null : cs.onSurfaceVariant,
    );

    final backgroundColor = _getBackgroundColor(cs, isEven);

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            Expanded(
              child: Text(
                address.name,
                style: style,
              ),
            ),
            SizedBox(
              width: 88,
              child: Center(
                child: RowActions(
                  onEdit: onEdit,
                  onDelete: onDelete,
                  active: address.active,
                  onView: onView,
                  onReactivate: onReactivate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.onReactivate,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onView;
  final VoidCallback? onReactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: address.active ? null : cs.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                address.name,
                style: style?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            RowActions(
              onEdit: onEdit,
              onDelete: onDelete,
              active: address.active,
              onView: onView,
              onReactivate: onReactivate,
            ),
          ],
        ),
      ),
    );
  }
}
