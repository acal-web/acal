import 'dart:async';

import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/widget/customer_filter_bar.dart';
import 'package:acalapp/features/customer/widget/invalid_data_badge.dart';
import 'package:acalapp/features/customer/widget/modal/delete_customer.dart';
import 'package:acalapp/features/customer/widget/modal/open_customer.dart';
import 'package:acalapp/shared/widgets/bool_text.dart';
import 'package:acalapp/shared/widgets/document_text.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/add_button.dart';
import 'package:acalapp/shared/widgets/table/row_actions.dart';
import 'package:flutter/material.dart';

const columnSpacing = 12.0;

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _service = CustomerService();
  final _scrollController = ScrollController();
  final List<Customer> _allCustomers = [];

  int _currentPage = 0;
  final int _pageSize = 100;
  int _totalCount = 0;
  bool _isLoading = false;
  bool _hasMorePages = true;
  String? _filterName;
  String? _filterDocument;
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
    _allCustomers.clear();
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
        document: _filterDocument,
        active: _filterActive,
        sort: 'name',
        sortAscending: true,
      );

      if (mounted) {
        setState(() {
          _allCustomers.addAll(result.data);
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
          _errorMessage = 'Erro ao carregar sócios';
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

  void _search({String? name, String? document, required bool? active}) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        _filterName = name;
        _filterDocument = document;
        _filterActive = active;
        await _loadFirstPage();
      }
    });
  }

  Future<void> _openForm({Customer? customer, bool readOnly = false}) async {
    if (await openCustomer(context, customer: customer, readOnly: readOnly)) {
      await _loadFirstPage();
    }
  }

  Future<void> _delete(Customer customer) async {
    if (await deleteCustomer(context, _service, customer)) {
      await _loadFirstPage();
    }
  }

  Future<void> _reactivate(Customer customer) async {
    try {
      await _service.restore(customer.id!);
      await _loadFirstPage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao reativar sócio')),
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
              subtitle: 'Gerencie os sócios cadastrados.',
              action: narrow ? AddButton(onPress: () => _openForm()) : null,
            ),
            const Divider(),
            CustomerFilterBar(onSearch: _search),
            const SizedBox(height: 8),
            Expanded(
              child: _errorMessage != null
                  ? _buildErrorView()
                  : _allCustomers.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhum sócio cadastrado.'))
                      : _buildTableWithInfiniteScroll(narrow),
            ),
            if (_allCustomers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Mostrando ${_allCustomers.length} de $_totalCount registros',
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
            itemCount: _allCustomers.length + (_isLoading ? 1 : 0),
            separatorBuilder: (_, _) =>
                narrow ? const SizedBox(height: 8) : const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == _allCustomers.length) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final customer = _allCustomers[index];
              final isEven = index.isEven;

              return narrow
                  ? _CustomerCard(
                      customer: customer,
                      onEdit: () => _openForm(customer: customer),
                      onDelete: () => _delete(customer),
                      onReactivate: () => _reactivate(customer),
                      onView: () => _openForm(customer: customer, readOnly: true),
                    )
                  : _CustomerRow(
                      customer: customer,
                      onEdit: () => _openForm(customer: customer),
                      onDelete: () => _delete(customer),
                      onReactivate: () => _reactivate(customer),
                      onView: () => _openForm(customer: customer, readOnly: true),
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
            flex: 6,
            child: Text('Nome', style: headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text('Documento', style: headerStyle),
          ),
          SizedBox(
            width: 90,
            child: Text('Nº Sócio', style: headerStyle),
          ),
          SizedBox(
            width: 90,
            child: Text('Votante', style: headerStyle),
          ),
          SizedBox(
            width: 140,
            child: Center(
              child: AddButton(onPress: onAddPress),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    this.onReactivate,
    this.onView,
    this.isEven = false,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReactivate;
  final VoidCallback? onView;
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
      color: customer.active ? null : cs.onSurfaceVariant,
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
              flex: 6,
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(customer.name, style: style),
                  ),
                  InvalidDataBadge(hasInvalidData: customer.hasInvalidData),
                ],
              ),
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
              child: Center(
                child: RowActions(
                  onEdit: onEdit,
                  onDelete: onDelete,
                  active: customer.active,
                  onReactivate: onReactivate,
                  onView: onView,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
    this.onReactivate,
    this.onView,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReactivate;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: customer.active ? null : cs.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: style?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  InvalidDataBadge(hasInvalidData: customer.hasInvalidData),
                ],
              ),
              const SizedBox(height: 8),
              DocumentText(customer.document, style: style),
              const SizedBox(height: 8),
              Row(
                spacing: 16,
                children: [
                  Text(
                    'Nº Sócio: ${customer.membershipNumber?.toString() ?? "—"}',
                    style: style?.copyWith(fontSize: 13),
                  ),
                  Text(
                    'Votante: ',
                    style: style?.copyWith(fontSize: 13),
                  ),
                  BoolText(
                    customer.voter,
                    style: style?.copyWith(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: RowActions(
                  onEdit: onEdit,
                  onDelete: onDelete,
                  active: customer.active,
                  onReactivate: onReactivate,
                  onView: onView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
