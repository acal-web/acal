import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice_candidate.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/formatters/decimal_input_formatter.dart';
import 'package:acalapp/shared/formatters/month_reference_formatter.dart';
import 'package:acalapp/shared/widgets/async_error_view.dart';
import 'package:acalapp/shared/widgets/page_header.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

const _checkboxColumnWidth = 56.0;
const _amountColumnWidth = 140.0;
const _waterMeterColumnWidth = 120.0;

// Mirrors WaterMeter#consumption / #water_consumed_value on the backend
// (api/app/models/water_meter.rb) — a live preview of the "água excedente"
// charge as HDR. INICIAL/FINAL are typed, before the invoice actually
// exists. Purely a preview: the real charge is computed server-side at
// generation time: if that formula ever changes, update this too.
const _waterMeterFreeTierLiters = 10000;
const _waterMeterExcessPricePerThousandLiters = 4.0;

double _previewWaterConsumedValue(double initialReading, double finalReading) {
  final consumption =
      (finalReading - initialReading) - _waterMeterFreeTierLiters;
  final excessLiters = consumption > 0 ? consumption : 0.0;
  return (excessLiters / 1000.0) * _waterMeterExcessPricePerThousandLiters;
}

class GenerateInvoicesPage extends StatefulWidget {
  const GenerateInvoicesPage({
    super.key,
    this.invoiceService,
    this.addressService,
  });

  final InvoiceService? invoiceService;
  final AddressService? addressService;

  @override
  State<GenerateInvoicesPage> createState() => _GenerateInvoicesPageState();
}

class _GenerateInvoicesPageState extends State<GenerateInvoicesPage> {
  late final InvoiceService _invoiceService;
  late final AddressService _addressService;

  DateTime _reference = DateTime(DateTime.now().year, DateTime.now().month);
  bool? _hasWaterMeter;
  String? _addressId;
  DateTime? _dueDate;

  List<Address> _addresses = [];
  bool _loadingAddresses = true;

  late Future<List<InvoiceCandidate>> _future;
  Set<String> _selected = {};
  bool _generating = false;

  late GlobalKey<_CandidatesCardState> _candidatesCardKey;

  @override
  void initState() {
    super.initState();
    _candidatesCardKey = GlobalKey();
    _invoiceService = widget.invoiceService ?? InvoiceService();
    _addressService = widget.addressService ?? AddressService();
    _addressService
        .findAll(size: 500)
        .then((result) {
          if (mounted) {
            setState(() {
              _addresses = result.data;
              _loadingAddresses = false;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao carregar endereços')),
            );
            setState(() => _loadingAddresses = false);
          }
        });
    _future = _fetch();
  }

  Future<List<InvoiceCandidate>> _fetch() {
    final future = _invoiceService.eligible(
      reference: _reference,
      hasWaterMeter: _hasWaterMeter,
      addressId: _addressId,
    );
    future
        .then((candidates) {
          if (mounted) {
            setState(() {
              final newCandidateIds = candidates
                  .map((c) => c.connectionId)
                  .toSet();
              _selected.retainAll(newCandidateIds);
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            AppToast.error(context, 'Erro ao carregar candidatos');
          }
        });
    return future;
  }

  void _search() => setState(() {
    _future = _fetch();
  });

  Future<void> _pickReference() async {
    final result = await pickMonthYear(
      context,
      initial: (year: _reference.year, month: _reference.month),
    );
    if (result != null) {
      setState(() => _reference = DateTime(result.year, result.month));
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _toggleAll(bool? checked, List<InvoiceCandidate> candidates) {
    setState(
      () => _selected = checked == true
          ? candidates.map((c) => c.connectionId).toSet()
          : {},
    );
  }

  void _toggle(String connectionId, bool? checked) {
    setState(() {
      if (checked == true) {
        _selected.add(connectionId);
      } else {
        _selected.remove(connectionId);
      }
    });
  }

  Future<void> _generate() async {
    // Guards against a fast double-click/double-tap firing this twice: the
    // button only disables on the next rebuild, so both taps can still hit
    // the old (enabled) widget if they land before that repaint.
    if (_generating) return;

    final dueDate = _dueDate;
    if (_selected.isEmpty || dueDate == null) return;

    setState(() => _generating = true);
    try {
      final waterMeters =
          _candidatesCardKey.currentState?.getWaterMetersData() ?? [];
      await _invoiceService.generate(
        connectionIds: _selected.toList(),
        reference: _reference,
        dueDate: dueDate,
        waterMeters: waterMeters,
      );
      if (mounted) {
        AppToast.success(context, 'Faturas geradas com sucesso.');
        setState(() {
          _future = _fetch();
        });
      }
    } catch (e) {
      if (mounted) AppToast.error(context, _errorMessage(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _errorMessage(Object e) {
    if (e is! ApiException) return 'Erro ao gerar faturas.';

    final errorCode = ApiErrorCode.fromCode(e.code);
    if (errorCode != null) return errorCode.description;

    return 'Erro ao gerar faturas.';
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
            const PageHeader(
              subtitle: 'Processamento e emissão de cobranças em lote.',
            ),
            const Divider(),
            const SizedBox(height: 8),
            _FilterBar(
              narrow: narrow,
              hasWaterMeter: _hasWaterMeter,
              reference: _reference,
              addresses: _addresses,
              loadingAddresses: _loadingAddresses,
              addressId: _addressId,
              onHasWaterMeterChanged: (v) => setState(() => _hasWaterMeter = v),
              onReferenceTap: _pickReference,
              onAddressChanged: (v) => setState(() => _addressId = v),
              onSearch: _search,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<InvoiceCandidate>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: FCircularProgress());
                  }
                  if (snapshot.hasError) {
                    return AsyncErrorView(
                      message: 'Erro ao carregar conexões elegíveis',
                      onRetry: _search,
                    );
                  }

                  final candidates = snapshot.data!;
                  final selectedAmount = candidates
                      .where((c) => _selected.contains(c.connectionId))
                      .fold<double>(0, (sum, c) => sum + c.amount);

                  // Disabled because this subtree is torn down and rebuilt
                  // wholesale on every _fetch() (candidates list swaps for a
                  // spinner and back) — under an ancestor SelectionArea
                  // (app_shell.dart), that mount/unmount of many Text nodes
                  // can leave a gesture recognizer stuck, silently eating
                  // taps app-wide until a full page reload
                  // (https://github.com/flutter/flutter/issues/141151).
                  return SelectionContainer.disabled(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _CandidatesCard(
                            key: _candidatesCardKey,
                            candidates: candidates,
                            selected: _selected,
                            selectedAmount: selectedAmount,
                            onToggleAll: (v) => _toggleAll(v, candidates),
                            onToggle: _toggle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GenerateBar(
                          foundCount: _selected.length,
                          amount: selectedAmount,
                          dueDate: _dueDate,
                          generating: _generating,
                          onDueDateTap: _pickDueDate,
                          onConfirm:
                              _selected.isEmpty ||
                                  _dueDate == null ||
                                  _generating
                              ? null
                              : _generate,
                        ),
                      ],
                    ),
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

class _FilterBar extends StatefulWidget {
  const _FilterBar({
    required this.narrow,
    required this.hasWaterMeter,
    required this.reference,
    required this.addresses,
    required this.loadingAddresses,
    required this.addressId,
    required this.onHasWaterMeterChanged,
    required this.onReferenceTap,
    required this.onAddressChanged,
    required this.onSearch,
  });

  final bool narrow;
  final bool? hasWaterMeter;
  final DateTime reference;
  final List<Address> addresses;
  final bool loadingAddresses;
  final String? addressId;
  final ValueChanged<bool?> onHasWaterMeterChanged;
  final VoidCallback onReferenceTap;
  final ValueChanged<String?> onAddressChanged;
  final VoidCallback onSearch;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late TextEditingController _referenceController;
  late Map<String, String?> _addressItems;

  @override
  void initState() {
    super.initState();
    _referenceController = TextEditingController(
      text: formatMonthReference(widget.reference),
    );
    _buildAddressItems();
  }

  void _buildAddressItems() {
    _addressItems = {
      'Todos': null,
      for (final address in widget.addresses) address.name: address.id,
    };
  }

  @override
  void didUpdateWidget(_FilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) {
      _referenceController.text = formatMonthReference(widget.reference);
    }
    if (oldWidget.addresses != widget.addresses) {
      _buildAddressItems();
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waterMeterField = FSelect<bool?>(
      items: const {
        'Todos': null,
        'Com Hidrômetro': true,
        'Sem Hidrômetro': false,
      },
      control: FSelectControl.managed(
        initial: widget.hasWaterMeter,
        onChange: widget.onHasWaterMeterChanged,
      ),
      label: const Text('Tipo Hidrômetro'),
    );

    final referenceField = FTextFormField(
      key: const Key('reference-field'),
      control: FTextFieldControl.managed(controller: _referenceController),
      readOnly: true,
      label: const Text('Período'),
      suffixBuilder: (context, style, variants) =>
          const Icon(Icons.calendar_today, size: 18),
      onTap: widget.onReferenceTap,
    );

    final addressField = FSelect<String?>(
      items: _addressItems,
      control: FSelectControl.managed(
        initial: widget.addressId,
        onChange: widget.loadingAddresses ? null : widget.onAddressChanged,
      ),
      label: const Text('Logradouro'),
      hint: widget.loadingAddresses
          ? 'Carregando...'
          : 'Selecione o endereço...',
      enabled: !widget.loadingAddresses,
    );

    final searchButton = SizedBox(
      width: widget.narrow ? double.infinity : null,
      child: FButton(
        mainAxisSize: MainAxisSize.min,
        onPress: widget.onSearch,
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
    );

    final fields = widget.narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              waterMeterField,
              const SizedBox(height: 8),
              referenceField,
              const SizedBox(height: 8),
              addressField,
              const SizedBox(height: 12),
              searchButton,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: waterMeterField),
                  const SizedBox(width: 12),
                  Expanded(child: referenceField),
                  const SizedBox(width: 12),
                  Expanded(child: addressField),
                ],
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: searchButton),
            ],
          );

    return fields;
  }
}

class _CandidatesCard extends StatefulWidget {
  const _CandidatesCard({
    super.key,
    required this.candidates,
    required this.selected,
    required this.selectedAmount,
    required this.onToggleAll,
    required this.onToggle,
  });

  final List<InvoiceCandidate> candidates;
  final Set<String> selected;
  final double selectedAmount;
  final ValueChanged<bool?> onToggleAll;
  final void Function(String connectionId, bool? checked) onToggle;

  @override
  State<_CandidatesCard> createState() => _CandidatesCardState();
}

class _CandidatesCardState extends State<_CandidatesCard> {
  String _sortBy = 'customerName';
  bool _sortAscending = true;
  final Map<String, Map<String, TextEditingController>> _waterMeterControllers =
      {};

  // Live "água excedente" preview per connection, kept in sync with the
  // initial/final controllers above via listeners — see
  // _previewWaterConsumedValue.
  final Map<String, double> _liveWaterExtra = {};

  List<InvoiceCandidate>? _cachedSortedCandidates;
  String? _lastSortBy;
  bool? _lastSortAscending;

  @override
  void dispose() {
    for (final controllers in _waterMeterControllers.values) {
      controllers['initial']?.dispose();
      controllers['final']?.dispose();
    }
    super.dispose();
  }

  Map<String, TextEditingController> _ensureControllers(
    String connectionId, {
    double? previousFinalReading,
  }) {
    return _waterMeterControllers.putIfAbsent(connectionId, () {
      final initialText = previousFinalReading != null
          ? previousFinalReading.toString()
          : '';
      final controllers = {
        'initial': TextEditingController(text: initialText),
        'final': TextEditingController(),
      };
      controllers['initial']!.addListener(
        () => _recomputeLiveExtra(connectionId),
      );
      controllers['final']!.addListener(
        () => _recomputeLiveExtra(connectionId),
      );
      return controllers;
    });
  }

  TextEditingController _getInitialController(
    String connectionId, {
    double? previousFinalReading,
  }) => _ensureControllers(
    connectionId,
    previousFinalReading: previousFinalReading,
  )['initial']!;

  TextEditingController _getFinalController(String connectionId) =>
      _ensureControllers(connectionId)['final']!;

  void _recomputeLiveExtra(String connectionId) {
    final controllers = _waterMeterControllers[connectionId];
    if (controllers == null) return;

    final initial = double.tryParse(controllers['initial']!.text);
    final finalReading = double.tryParse(controllers['final']!.text);

    final extra = (initial != null && finalReading != null)
        ? _previewWaterConsumedValue(initial, finalReading)
        : 0.0;

    if (_liveWaterExtra[connectionId] == extra) return;
    setState(() => _liveWaterExtra[connectionId] = extra);
  }

  double get _selectedLiveWaterExtra => widget.selected.fold<double>(
    0,
    (sum, id) => sum + (_liveWaterExtra[id] ?? 0),
  );

  List<Map<String, dynamic>> getWaterMetersData() {
    return _waterMeterControllers.entries
        .where(
          (e) =>
              e.value['initial']!.text.isNotEmpty &&
              e.value['final']!.text.isNotEmpty,
        )
        .map(
          (e) => {
            'connection_id': e.key,
            'initial_reading': double.parse(e.value['initial']!.text),
            'final_reading': double.parse(e.value['final']!.text),
          },
        )
        .toList();
  }

  List<InvoiceCandidate> get _sortedCandidates {
    if (_cachedSortedCandidates != null &&
        _lastSortBy == _sortBy &&
        _lastSortAscending == _sortAscending) {
      return _cachedSortedCandidates!;
    }

    final sorted = [...widget.candidates];

    sorted.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'customerName':
          comparison = a.customerName.compareTo(b.customerName);
        case 'addressName':
          comparison = a.fullAddress.compareTo(b.fullAddress);
        case 'categoryName':
          comparison = a.categoryName.compareTo(b.categoryName);
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
        default:
          comparison = 0;
      }

      return _sortAscending ? comparison : -comparison;
    });

    _lastSortBy = _sortBy;
    _lastSortAscending = _sortAscending;
    return _cachedSortedCandidates = sorted;
  }

  void _sort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final headerStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);
    final allSelected =
        widget.candidates.isNotEmpty &&
        widget.selected.length == widget.candidates.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _SortableHeaderCell(
                  label: 'SÓCIO',
                  sortBy: 'customerName',
                  currentSort: _sortBy,
                  ascending: _sortAscending,
                  onSort: _sort,
                  style: headerStyle,
                ),
              ),
              Expanded(
                flex: 3,
                child: _SortableHeaderCell(
                  label: 'ENDEREÇO',
                  sortBy: 'addressName',
                  currentSort: _sortBy,
                  ascending: _sortAscending,
                  onSort: _sort,
                  style: headerStyle,
                ),
              ),
              Expanded(
                flex: 2,
                child: _SortableHeaderCell(
                  label: 'CATEGORIA',
                  sortBy: 'categoryName',
                  currentSort: _sortBy,
                  ascending: _sortAscending,
                  onSort: _sort,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: _waterMeterColumnWidth,
                child: Text('HDR. INICIAL', style: headerStyle),
              ),
              SizedBox(
                width: _waterMeterColumnWidth,
                child: Text('HDR. FINAL', style: headerStyle),
              ),
              SizedBox(
                width: _amountColumnWidth,
                child: _SortableHeaderCell(
                  label: 'VALOR TOTAL',
                  sortBy: 'amount',
                  currentSort: _sortBy,
                  ascending: _sortAscending,
                  onSort: _sort,
                  style: headerStyle,
                ),
              ),
              SizedBox(
                width: _checkboxColumnWidth,
                child: FCheckbox(
                  value: allSelected,
                  onChange: widget.candidates.isEmpty
                      ? null
                      : widget.onToggleAll,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (widget.candidates.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'Nenhuma conexão elegível para o período selecionado.',
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: _sortedCandidates.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final candidate = _sortedCandidates[i];
                final checked = widget.selected.contains(
                  candidate.connectionId,
                );

                return Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () =>
                        widget.onToggle(candidate.connectionId, !checked),
                    child: ColoredBox(
                      color: cs.surfaceContainer.withValues(
                        alpha: i.isEven ? 0.2 : 0.4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(candidate.customerName),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(candidate.fullAddress),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(candidate.categoryName),
                            ),
                            if (candidate.hasWaterMeter) ...[
                              SizedBox(
                                width: _waterMeterColumnWidth,
                                child: FTextFormField(
                                  control: FTextFieldControl.managed(
                                    controller: _getInitialController(
                                      candidate.connectionId,
                                      previousFinalReading:
                                          candidate.previousMeterFinalReading,
                                    ),
                                  ),
                                  hint: '0.0',
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [DecimalInputFormatter()],
                                ),
                              ),
                              SizedBox(
                                width: _waterMeterColumnWidth,
                                child: FTextFormField(
                                  control: FTextFieldControl.managed(
                                    controller: _getFinalController(
                                      candidate.connectionId,
                                    ),
                                  ),
                                  hint: '0.0',
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [DecimalInputFormatter()],
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: _waterMeterColumnWidth,
                                child: Center(
                                  child: Text(
                                    '0.0',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: _waterMeterColumnWidth,
                                child: Center(
                                  child: Text(
                                    '0.0',
                                    style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(
                              width: _amountColumnWidth,
                              child: Text(
                                formatBRL(
                                  candidate.amount +
                                      (_liveWaterExtra[candidate
                                              .connectionId] ??
                                          0),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: _checkboxColumnWidth,
                              child: FCheckbox(
                                value: checked,
                                onChange: (v) =>
                                    widget.onToggle(candidate.connectionId, v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Container(
          color: cs.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(
                'Total (${widget.selected.length})',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              Text(
                formatBRL(widget.selectedAmount + _selectedLiveWaterExtra),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SortableHeaderCell extends StatelessWidget {
  const _SortableHeaderCell({
    required this.label,
    required this.sortBy,
    required this.currentSort,
    required this.ascending,
    required this.onSort,
    this.style,
  });

  final String label;
  final String sortBy;
  final String currentSort;
  final bool ascending;
  final Function(String) onSort;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = currentSort == sortBy;
    final icon = !isActive
        ? Icons.unfold_more
        : ascending
        ? Icons.arrow_upward
        : Icons.arrow_downward;

    return GestureDetector(
      onTap: () => onSort(sortBy),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Flexible(child: Text(label, style: style)),
          Icon(
            icon,
            size: 16,
            color: isActive ? cs.primary : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _GenerateBar extends StatefulWidget {
  const _GenerateBar({
    required this.foundCount,
    required this.amount,
    required this.dueDate,
    required this.generating,
    required this.onDueDateTap,
    required this.onConfirm,
  });

  final int foundCount;
  final double amount;
  final DateTime? dueDate;
  final bool generating;
  final VoidCallback onDueDateTap;
  final VoidCallback? onConfirm;

  @override
  State<_GenerateBar> createState() => _GenerateBarState();
}

class _GenerateBarState extends State<_GenerateBar> {
  late TextEditingController _dueDateController;

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  void initState() {
    super.initState();
    _dueDateController = TextEditingController(
      text: widget.dueDate == null ? '' : _formatDate(widget.dueDate!),
    );
  }

  @override
  void didUpdateWidget(_GenerateBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dueDate != widget.dueDate) {
      _dueDateController.text = widget.dueDate == null
          ? ''
          : _formatDate(widget.dueDate!);
    }
  }

  @override
  void dispose() {
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow =
        MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    final infoText = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: 8),
        Text(
          '${widget.foundCount} encontradas, ${formatBRL(widget.amount)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );

    final dueDateField = SizedBox(
      width: 180,
      child: FTextFormField(
        key: const Key('due-date-field'),
        control: FTextFieldControl.managed(controller: _dueDateController),
        readOnly: true,
        label: const Text('Vencimento'),
        hint: '--/--/----',
        suffixBuilder: (context, style, variants) =>
            const Icon(Icons.calendar_today, size: 18),
        onTap: widget.onDueDateTap,
      ),
    );

    final confirmButton = SizedBox(
      width: narrow ? double.infinity : null,
      child: FButton(
        mainAxisSize: MainAxisSize.min,
        onPress: widget.onConfirm,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.generating)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: FCircularProgress(size: FCircularProgressSizeVariant.xs),
              )
            else ...[
              const Icon(Icons.check, size: 18),
              const SizedBox(width: 8),
            ],
            const Text('Confirmar Geração'),
          ],
        ),
      ),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          infoText,
          const SizedBox(height: 12),
          dueDateField,
          const SizedBox(height: 12),
          confirmButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [dueDateField, const SizedBox(width: 16), confirmButton],
        ),
      ],
    );
  }
}
