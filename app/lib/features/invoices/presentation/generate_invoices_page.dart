import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/invoices/data/invoice_service.dart';
import 'package:acalapp/features/invoices/domain/invoice_candidate.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
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

class GenerateInvoicesPage extends StatefulWidget {
  const GenerateInvoicesPage({super.key, this.invoiceService, this.addressService});

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

  @override
  void initState() {
    super.initState();
    _invoiceService = widget.invoiceService ?? InvoiceService();
    _addressService = widget.addressService ?? AddressService();
    _addressService.findAll(size: 500).then((result) {
      if (mounted) setState(() => _addresses = result.data);
    }).whenComplete(() {
      if (mounted) setState(() => _loadingAddresses = false);
    });
    _future = _fetch();
  }

  Future<List<InvoiceCandidate>> _fetch() {
    final future = _invoiceService.eligible(
      reference: _reference,
      hasWaterMeter: _hasWaterMeter,
      addressId: _addressId,
    );
    future.then((candidates) {
      if (mounted) setState(() => _selected = candidates.map((c) => c.connectionId).toSet());
    });
    return future;
  }

  void _search() => setState(() {
        _future = _fetch();
      });

  Future<void> _pickReference() async {
    final result = await pickMonthYear(context, initial: (year: _reference.year, month: _reference.month));
    if (result != null) setState(() => _reference = DateTime(result.year, result.month));
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
    setState(() => _selected = checked == true ? candidates.map((c) => c.connectionId).toSet() : {});
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
    final dueDate = _dueDate;
    if (_selected.isEmpty || dueDate == null) return;

    setState(() => _generating = true);
    try {
      await _invoiceService.generate(connectionIds: _selected.toList(), reference: _reference, dueDate: dueDate);
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
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

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
                    return AsyncErrorView(message: 'Erro ao carregar conexões elegíveis', onRetry: _search);
                  }

                  final candidates = snapshot.data!;
                  final selectedAmount = candidates
                      .where((c) => _selected.contains(c.connectionId))
                      .fold<double>(0, (sum, c) => sum + c.amount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _CandidatesCard(
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
                        onConfirm: _selected.isEmpty || _dueDate == null || _generating ? null : _generate,
                      ),
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

class _FilterBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final waterMeterField = FSelect<bool?>(
      items: const {'Todos': null, 'Com Hidrômetro': true, 'Sem Hidrômetro': false},
      control: FSelectControl.managed(initial: hasWaterMeter, onChange: onHasWaterMeterChanged),
      label: const Text('Tipo Hidrômetro'),
    );

    final referenceField = FTextFormField(
      key: const Key('reference-field'),
      control: FTextFieldControl.managed(controller: TextEditingController(text: formatMonthReference(reference))),
      readOnly: true,
      label: const Text('Período'),
      suffixBuilder: (context, style, variants) => const Icon(Icons.calendar_today, size: 18),
      onTap: onReferenceTap,
    );

    final addressField = FSelect<String?>(
      items: {
        'Todos': null,
        for (final address in addresses) address.fullAddress: address.id,
      },
      control: FSelectControl.managed(initial: addressId, onChange: loadingAddresses ? null : onAddressChanged),
      label: const Text('Logradouro'),
      hint: loadingAddresses ? 'Carregando...' : 'Selecione o endereço...',
      enabled: !loadingAddresses,
    );

    final searchButton = SizedBox(
      width: narrow ? double.infinity : null,
      child: FButton(
        mainAxisSize: MainAxisSize.min,
        onPress: onSearch,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.search, size: 18), SizedBox(width: 8), Text('Consultar')],
        ),
      ),
    );

    final fields = narrow
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

    return Card(
      elevation: 1,
      child: Padding(
        padding: LayoutConfig.pagePadding(narrow),
        child: fields,
      ),
    );
  }
}

class _CandidatesCard extends StatelessWidget {
  const _CandidatesCard({
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allSelected = candidates.isNotEmpty && selected.length == candidates.length;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('SÓCIO', style: Theme.of(context).textTheme.labelLarge)),
                Expanded(flex: 3, child: Text('ENDEREÇO', style: Theme.of(context).textTheme.labelLarge)),
                Expanded(flex: 2, child: Text('CATEGORIA', style: Theme.of(context).textTheme.labelLarge)),
                SizedBox(width: _amountColumnWidth, child: Text('VALOR TOTAL', style: Theme.of(context).textTheme.labelLarge)),
                SizedBox(width: _waterMeterColumnWidth, child: Text('HDR. INICIAL', style: Theme.of(context).textTheme.labelLarge)),
                SizedBox(
                  width: _checkboxColumnWidth,
                  child: FCheckbox(
                    value: allSelected,
                    onChange: candidates.isEmpty ? null : onToggleAll,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (candidates.isEmpty)
            const Expanded(child: Center(child: Text('Nenhuma conexão elegível para o período selecionado.')))
          else
            Expanded(
              child: ListView.separated(
                itemCount: candidates.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final candidate = candidates[i];
                  final checked = selected.contains(candidate.connectionId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text(candidate.customerName)),
                        Expanded(flex: 3, child: Text(candidate.addressName)),
                        Expanded(flex: 2, child: Text(candidate.categoryName)),
                        SizedBox(width: _amountColumnWidth, child: Text(formatBRL(candidate.amount))),
                        const SizedBox(width: _waterMeterColumnWidth, child: Text('0.0')),
                        SizedBox(
                          width: _checkboxColumnWidth,
                          child: FCheckbox(
                            value: checked,
                            onChange: (v) => onToggle(candidate.connectionId, v),
                          ),
                        ),
                      ],
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
                Text('Total (${selected.length})', style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                Text(formatBRL(selectedAmount), style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateBar extends StatelessWidget {
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < LayoutConfig.narrowBreakpoint;

    final infoText = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 18),
        const SizedBox(width: 8),
        Text('$foundCount encontradas, ${formatBRL(amount)}', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );

    final dueDateField = SizedBox(
      width: 180,
      child: FTextFormField(
        key: const Key('due-date-field'),
        control: FTextFieldControl.managed(
          controller: TextEditingController(text: dueDate == null ? '' : _formatDate(dueDate!)),
        ),
        readOnly: true,
        label: const Text('Vencimento'),
        hint: '--/--/----',
        suffixBuilder: (context, style, variants) => const Icon(Icons.calendar_today, size: 18),
        onTap: onDueDateTap,
      ),
    );

    final confirmButton = SizedBox(
      width: narrow ? double.infinity : null,
      child: FButton(
        mainAxisSize: MainAxisSize.min,
        onPress: onConfirm,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (generating)
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
          children: [
            dueDateField,
            const SizedBox(width: 16),
            confirmButton,
          ],
        ),
      ],
    );
  }
}
