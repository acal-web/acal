import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_select_field.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/widget/customer_select_field.dart';
import 'package:acalapp/shared/widgets/period_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum _InvoiceStatus {
  all('Todos', null),
  paid('Pagos', 'paid'),
  unpaid('Abertos', 'unpaid');

  const _InvoiceStatus(this.label, this.value);
  final String label;
  final String? value;
}

class InvoiceFilterBar extends StatefulWidget {
  const InvoiceFilterBar({
    super.key,
    required this.onSearch,
    this.customerService,
    this.addressService,
  });

  final void Function({
    MonthYear? period,
    String? customerId,
    String? addressId,
    String? status,
  }) onSearch;
  final CustomerService? customerService;
  final AddressService? addressService;

  @override
  State<InvoiceFilterBar> createState() => _InvoiceFilterBarState();
}

class _InvoiceFilterBarState extends State<InvoiceFilterBar> {
  late final CustomerService _customerService;
  late final AddressService _addressService;

  MonthYear? _period;
  Customer? _customer;
  Address? _address;
  _InvoiceStatus _status = _InvoiceStatus.all;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _customerService = widget.customerService ?? CustomerService();
    _addressService = widget.addressService ?? AddressService();
  }

  void _search() {
    widget.onSearch(
      period: _period,
      customerId: _customer?.id,
      addressId: _address?.id,
      status: _status.value,
    );
  }

  void _clear() {
    setState(() {
      _period = null;
      _customer = null;
      _address = null;
      _status = _InvoiceStatus.all;
    });
    widget.onSearch(
      period: null,
      customerId: null,
      addressId: null,
      status: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < LayoutConfig.narrowBreakpoint;

        final periodField = PeriodFilterButton(
          period: _period,
          onChanged: (p) => setState(() => _period = p),
        );

        final customerField = CustomerSelectField(
          customerService: _customerService,
          initialValue: _customer,
          onSelected: (c) => setState(() => _customer = c),
        );

        final addressField = AddressSelectField(
          addressService: _addressService,
          initialValue: _address,
          onSelected: (a) => setState(() => _address = a),
        );

        final statusField = FSelect<_InvoiceStatus>(
          items: {
            for (final status in _InvoiceStatus.values) status.label: status
          },
          control: FSelectControl.managed(
            initial: _status,
            onChange: (v) => setState(() => _status = v ?? _InvoiceStatus.all),
          ),
          label: const Text('Situação'),
        );

        final searchButton = FButton(
          onPress: _search,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 18),
              SizedBox(width: 8),
              Text('Consultar')
            ],
          ),
        );

        final clearButton = FButton(
          variant: FButtonVariant.outline,
          onPress: _clear,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.clear, size: 18), SizedBox(width: 8), Text('Limpar')],
          ),
        );

        final fields = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  periodField,
                  const SizedBox(height: 12),
                  customerField,
                  const SizedBox(height: 12),
                  addressField,
                  const SizedBox(height: 12),
                  statusField,
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: clearButton),
                      const SizedBox(width: 8),
                      Expanded(child: searchButton),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 200,
                          child: periodField,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 300,
                          child: customerField,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 300,
                          child: addressField,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: statusField,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(width: 110, child: clearButton),
                      const SizedBox(width: 8),
                      SizedBox(width: 110, child: searchButton),
                    ],
                  ),
                ],
              );

        final cs = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(
              color: cs.surfaceContainerHigh,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: const Icon(Icons.expand_more, size: 20),
                      ),
                      const SizedBox(width: 4),
                      Text('Filtros', style: Theme.of(context).textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          margin: EdgeInsets.zero,
                          color: cs.surfaceContainerHigh,
                          surfaceTintColor: Colors.transparent,
                          child: Padding(
                            padding: LayoutConfig.pagePadding(narrow),
                            child: fields,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
