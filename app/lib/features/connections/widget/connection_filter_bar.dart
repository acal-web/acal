import 'package:acalapp/core/config/layout_config.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_select_field.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/widget/category_select_field.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/widget/customer_select_field.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

typedef ConnectionFilters = ({
  String? customerId,
  String? addressName,
  String? categoryId,
  bool? active,
});

class ConnectionFilterBar extends StatefulWidget {
  const ConnectionFilterBar({
    super.key,
    required this.onSearch,
    this.categoryService,
    this.customerService,
  });

  final void Function(ConnectionFilters filters) onSearch;
  final CategoryService? categoryService;
  final CustomerService? customerService;

  @override
  State<ConnectionFilterBar> createState() => _ConnectionFilterBarState();
}

class _ConnectionFilterBarState extends State<ConnectionFilterBar> {
  late final AddressService _addressService;
  late final CategoryService _categoryService;
  late final CustomerService _customerService;
  Address? _address;
  Customer? _customer;
  Category? _category;
  bool? _active;
  bool _expanded = false;
  int _filterKey = 0;

  @override
  void initState() {
    super.initState();
    _addressService = AddressService();
    _categoryService = widget.categoryService ?? CategoryService();
    _customerService = widget.customerService ?? CustomerService();
  }

  void _search() => widget.onSearch((
        customerId: _customer?.id,
        addressName: _address?.name,
        categoryId: _category?.id,
        active: _active,
      ));

  void _clear() {
    setState(() {
      _customer = null;
      _address = null;
      _category = null;
      _active = null;
      _filterKey++;
    });
    widget.onSearch((customerId: null, addressName: null, categoryId: null, active: null));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < LayoutConfig.narrowBreakpoint;

        final customerField = CustomerSelectField(
          key: ValueKey(_filterKey),
          customerService: _customerService,
          initialValue: _customer,
          includeInactive: true,
          onSelected: (c) => setState(() => _customer = c),
        );

        final addressField = AddressSelectField(
          key: ValueKey(_filterKey),
          addressService: _addressService,
          initialValue: _address,
          onSelected: (a) => setState(() => _address = a),
        );

        final categoryField = CategorySelectField(
          categoryService: _categoryService,
          initialValue: _category,
          onSelected: (c) => _category = c,
        );

        final activeField = FSelect<bool?>(
          key: ValueKey(_filterKey),
          items: const {'Todas': null, 'Ativas': true, 'Encerradas': false},
          control: FSelectControl.managed(initial: _active, onChange: (v) => setState(() => _active = v)),
          label: const Text('Situação'),
        );

        final searchButtonNarrow = Expanded(
          child: FButton(
            onPress: _search,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.search, size: 18), SizedBox(width: 8), Text('Consultar')],
            ),
          ),
        );

        final clearButtonNarrow = Expanded(
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: _clear,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.clear, size: 18), SizedBox(width: 8), Text('Limpar')],
            ),
          ),
        );

        final searchButtonWide = SizedBox(
          child: FButton(
            onPress: _search,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.search, size: 18), SizedBox(width: 8), Text('Consultar')],
            ),
          ),
        );

        final clearButtonWide = SizedBox(
          child: FButton(
            variant: FButtonVariant.outline,
            onPress: _clear,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.clear, size: 18), SizedBox(width: 8), Text('Limpar')],
            ),
          ),
        );

        final fields = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  customerField,
                  const SizedBox(height: 8),
                  addressField,
                  const SizedBox(height: 8),
                  categoryField,
                  const SizedBox(height: 8),
                  activeField,
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      clearButtonNarrow,
                      const SizedBox(width: 8),
                      searchButtonNarrow,
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: customerField),
                      const SizedBox(width: 8),
                      Expanded(child: addressField),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: categoryField),
                      const SizedBox(width: 8),
                      Expanded(child: activeField),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(flex: 8),
                      Expanded(flex: 2, child: clearButtonWide),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: searchButtonWide),
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
