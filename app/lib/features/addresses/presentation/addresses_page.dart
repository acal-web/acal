import 'dart:ui';

import 'package:acalapp/core/models/paged_result.dart';
import 'package:acalapp/core/models/pagination.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/presentation/address_form_page.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _service.findAll(page: _page);
  }

  void _load() => setState(() => _future = _service.findAll(page: _page));

  void _goToPage(int page) => setState(() {
        _page = page;
        _future = _service.findAll(page: _page);
      });

  Future<void> _openForm({Address? address}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const SizedBox.expand(),
            ),
          ),
          Center(child: AddressFormPage(address: address)),
        ],
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Logradouros', style: theme.textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Gerencie os pontos de distribuição de água',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar Logradouro'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Buscar por nome, tipo ou bairro...',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filtros'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Exportar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<PagedResult<Address>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: cs.error, size: 40),
                          const SizedBox(height: 12),
                          Text('Erro ao carregar endereços',
                              style: TextStyle(color: cs.error)),
                          const SizedBox(height: 8),
                          OutlinedButton(
                              onPressed: _load,
                              child: const Text('Tentar novamente')),
                        ],
                      ),
                    );
                  }

                  final result = snapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Card(
                          child: Column(
                            children: [
                              _TableHeader(),
                              const Divider(height: 1),
                              if (result.data.isEmpty)
                                const Expanded(
                                  child: Center(
                                    child: Text('Nenhum endereço cadastrado.'),
                                  ),
                                )
                              else
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: result.data.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) => _AddressRow(
                                      address: result.data[i],
                                      onTap: () =>
                                          _openForm(address: result.data[i]),
                                    ),
                                  ),
                                ),
                              const Divider(height: 1),
                              _PaginationBar(
                                pagination: result.pagination,
                                itemCount: result.data.length,
                                onPageChanged: _goToPage,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SummaryCard(total: result.pagination.totalElements),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('NOME DO LOGRADOURO', style: style)),
          Expanded(flex: 2, child: Text('TIPO', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          SizedBox(width: 80, child: Text('AÇÕES', style: style)),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({required this.address, required this.onTap});

  final Address address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.location_on_outlined,
                        size: 18, color: cs.secondary),
                  ),
                  const SizedBox(width: 12),
                  Text(address.fullAddress, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(address.type, style: theme.textTheme.bodyMedium),
            ),
            const Expanded(flex: 2, child: SizedBox()),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pagination,
    required this.itemCount,
    required this.onPageChanged,
  });

  final Pagination pagination;
  final int itemCount;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = pagination;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Mostrando $itemCount de ${p.totalElements} registros',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Text('Página ${p.displayPage} de ${p.totalPages}',
              style: theme.textTheme.bodySmall),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed:
                p.prevPage != null ? () => onPageChanged(p.prevPage!) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed:
                p.nextPage != null ? () => onPageChanged(p.nextPage!) : null,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Logradouros',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text('$total', style: theme.textTheme.displaySmall),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.maps_home_work_outlined,
                  color: cs.secondary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
