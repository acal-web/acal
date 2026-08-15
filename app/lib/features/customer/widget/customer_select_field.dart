import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/widgets/search_select_field.dart';
import 'package:flutter/material.dart';

class CustomerSelectField extends StatefulWidget {
  const CustomerSelectField({
    super.key,
    required this.customerService,
    this.initialValue,
    required this.onSelected,
    this.label = 'Sócio',
    this.hintText = 'Buscar por nome ou documento',
    this.includeInactive = false,
    this.validator,
  });

  final CustomerService customerService;
  final Customer? initialValue;
  final ValueChanged<Customer?> onSelected;
  final String label;
  final String hintText;
  final bool includeInactive;
  final FormFieldValidator<Customer>? validator;

  @override
  State<CustomerSelectField> createState() => _CustomerSelectFieldState();
}

class _CustomerSelectFieldState extends State<CustomerSelectField> {
  late Customer? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  Future<List<Customer>> _search(String query) async {
    final hasDigits = RegExp(r'[0-9]').hasMatch(query);
    final active = widget.includeInactive ? null : true;
    final pages = await Future.wait([
      widget.customerService.findAll(name: query, size: 5, active: active),
      if (hasDigits) widget.customerService.findAll(document: query, size: 5, active: active),
    ]);
    final seen = <String>{};
    final results = <Customer>[];
    for (final page in pages) {
      for (final customer in page.data) {
        if (customer.id != null && seen.add(customer.id!)) {
          if (!widget.includeInactive && !customer.active) {
            continue;
          }
          results.add(customer);
        }
      }
    }
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  void _handleSelected(Customer? customer) {
    setState(() => _selected = customer);
    widget.onSelected(customer);
  }

  void _handleClear() {
    setState(() => _selected = null);
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            SearchSelectField<Customer>(
              label: widget.label,
              hintText: widget.hintText,
              initialValue: _selected,
              search: _search,
              labelBuilder: (c) => c.name,
              subtitleBuilder: (c) {
                final inactiveLabel = !c.active ? ' (inativo)' : '';
                return '${c.document}$inactiveLabel';
              },
              onSelected: _handleSelected,
              validator: widget.validator,
            ),
            if (_selected != null)
              Positioned(
                right: 16,
                top: 48,
                child: GestureDetector(
                  onTap: _handleClear,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.clear,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
