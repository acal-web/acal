import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_select_field.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/overdue_connection.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/table/collapsible_filter_panel.dart';
import 'package:acalapp/shared/widgets/table/data_table_card.dart' show columnSpacing;
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:printing/printing.dart';

const _countColumnWidth = 90.0;
const _totalColumnWidth = 130.0;
const _actionColumnWidth = 56.0;

/// Days past which the API flags a connection as subject to having its
/// service cut off — mirrors `Invoices::OverdueConnectionsService::CUTOFF_DAYS`.
const cutoffDays = 59;

/// Lists connections with unpaid invoices overdue by more than a threshold,
/// letting the user download the dunning letter (carta de cobrança) for one
/// connection or for all of them at once — mirrors the legacy rc_cobranca
/// report family, driven off `GET /invoices/overdue` + `GET /invoices/cobranca_pdf`.
///
/// Laid out like the Caixa screen: collapsible filters, a paged table with
/// infinite scroll, and a footer with the record count and the open total.
class CobrancaPage extends StatefulWidget {
  const CobrancaPage({super.key, this.invoiceService, this.addressService});

  final InvoiceService? invoiceService;
  final AddressService? addressService;

  @override
  State<CobrancaPage> createState() => _CobrancaPageState();
}

class _CobrancaPageState extends State<CobrancaPage> {
  late final InvoiceService _service;
  late final AddressService _addressService;
  final _scrollController = ScrollController();
  final List<OverdueConnection> _allGroups = [];

  int _days = 30;
  Address? _address;
  int _currentPage = 0;
  final int _pageSize = 25;
  int _totalCount = 0;
  double _totalAmount = 0;
  bool _isLoading = false;
  bool _downloadingAll = false;
  bool _hasMorePages = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.invoiceService ?? InvoiceService();
    _addressService = widget.addressService ?? AddressService();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    _allGroups.clear();
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
      final result = await _service.overdue(
        page: _currentPage,
        size: _pageSize,
        days: _days,
        addressId: _address?.id,
      );

      if (mounted) {
        setState(() {
          _allGroups.addAll(result.page.data);
          _totalCount = result.page.pagination.totalElements;
          _totalAmount = result.totalAmount;
          _hasMorePages = result.page.pagination.nextPage != null;
          _currentPage++;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erro ao carregar cobranças em aberto';
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

  void _changeDays(int? days) {
    if (days == null || days == _days) return;
    setState(() => _days = days);
    _loadFirstPage();
  }

  void _changeAddress(Address? address) {
    if (address?.id == _address?.id) return;
    setState(() => _address = address);
    _loadFirstPage();
  }

  Future<void> _downloadOne(String connectionId) async {
    try {
      await Printing.layoutPdf(onLayout: (_) => _service.cobrancaPdf(connectionId: connectionId, days: _days));
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao gerar a carta de cobrança.');
    }
  }

  Future<void> _downloadAll() async {
    setState(() => _downloadingAll = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _service.cobrancaPdf(days: _days, addressId: _address?.id),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Erro ao gerar as cartas de cobrança.');
    } finally {
      if (mounted) setState(() => _downloadingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;
    final cutoffCount = _allGroups.where((group) => group.subjectToCutoff).length;

    return Scaffold(
      body: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              subtitle: 'Cartas de aviso para ligações com faturas vencidas e não pagas.',
              action: FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: _allGroups.isEmpty || _downloadingAll ? null : _downloadAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(_downloadingAll ? 'Gerando...' : 'Baixar Todas as Cartas'),
                  ],
                ),
              ),
            ),
            const Divider(),
            CollapsibleFilterPanel(
              builder: (context, narrow) => Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 180,
                    child: FSelect<int>(
                      items: const {'30 dias': 30, '60 dias': 60, '90 dias': 90},
                      control: FSelectControl.managed(initial: _days, onChange: _changeDays),
                      label: const Text('Vencidas há mais de'),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: AddressSelectField(
                      addressService: _addressService,
                      initialValue: _address,
                      onSelected: _changeAddress,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (cutoffCount > 0) _CutoffBanner(count: cutoffCount),
            Expanded(
              child: _errorMessage != null
                  ? AsyncErrorView(message: _errorMessage!, onRetry: _loadFirstPage)
                  : _allGroups.isEmpty && !_isLoading
                      ? const Center(child: Text('Nenhuma fatura vencida encontrada.'))
                      : _buildTableWithInfiniteScroll(),
            ),
            if (_allGroups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'Mostrando ${_allGroups.length} de $_totalCount registros',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Total em aberto: ${formatBRL(_totalAmount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableWithInfiniteScroll() {
    return Column(
      children: [
        const _TableHeader(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _allGroups.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _allGroups.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return Column(
                children: [
                  _OverdueRow(
                    group: _allGroups[index],
                    isEven: index.isEven,
                    onDownload: _downloadOne,
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

class _CutoffBanner extends StatelessWidget {
  const _CutoffBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ligacoes = count == 1 ? 'ligação' : 'ligações';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count $ligacoes com débitos vencidos há mais de $cutoffDays dias — serviço passível de corte.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        spacing: columnSpacing,
        children: [
          Expanded(flex: 3, child: Text('SÓCIO', style: headerStyle)),
          Expanded(flex: 3, child: Text('LIGAÇÃO', style: headerStyle)),
          SizedBox(width: _countColumnWidth, child: Text('FATURAS', style: headerStyle)),
          SizedBox(width: _totalColumnWidth, child: Text('TOTAL', style: headerStyle)),
          const SizedBox(width: _actionColumnWidth),
        ],
      ),
    );
  }
}

class _OverdueRow extends StatelessWidget {
  const _OverdueRow({required this.group, required this.onDownload, this.isEven = false});

  final OverdueConnection group;
  final void Function(String connectionId) onDownload;
  final bool isEven;

  static Color _backgroundColor(ColorScheme cs, bool isEven) => isEven
      ? cs.surfaceContainer.withValues(alpha: 0.2)
      : cs.surfaceContainer.withValues(alpha: 0.4);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium;

    return ColoredBox(
      color: _backgroundColor(cs, isEven),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: columnSpacing,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (group.subjectToCutoff) ...[
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: cs.error,
                      semanticLabel: 'Passível de corte — débitos há mais de $cutoffDays dias',
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(child: Text(group.customerName, style: style)),
                ],
              ),
            ),
            Expanded(flex: 3, child: Text('${group.addressName}, ${group.connectionNumber}', style: style)),
            SizedBox(width: _countColumnWidth, child: Text('${group.invoices.length}', style: style)),
            SizedBox(width: _totalColumnWidth, child: Text(formatBRL(group.totalAmount), style: style)),
            SizedBox(
              width: _actionColumnWidth,
              child: FButton(
                variant: FButtonVariant.ghost,
                size: FButtonSizeVariant.sm,
                mainAxisSize: MainAxisSize.min,
                semanticsTooltip: 'Baixar carta de cobrança',
                onPress: () => onDownload(group.connectionId),
                child: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
