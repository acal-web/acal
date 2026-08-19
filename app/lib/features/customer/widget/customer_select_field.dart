import 'dart:async';

import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

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
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<List<Customer>> _filter(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return [];

    final hasDigits = RegExp(r'[0-9]').hasMatch(trimmed);
    final active = widget.includeInactive ? null : true;
    final pages = await Future.wait([
      widget.customerService.findAll(name: trimmed, size: 5, active: active),
      if (hasDigits) widget.customerService.findAll(document: trimmed, size: 5, active: active),
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

  @override
  Widget build(BuildContext context) {
    return FSelect<Customer>.searchBuilder(
      format: (c) => c.name,
      filter: (query) {
        _debounceTimer?.cancel();
        final completer = Completer<Iterable<Customer>>();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
          final results = await _filter(query);
          completer.complete(results);
        });
        return completer.future;
      },
      contentBuilder: (context, query, values) => [
        for (final customer in values)
          FSelectItem.item(
            title: Text(customer.name),
            subtitle: Text(
              customer.active ? customer.document : '${customer.document} (inativo)',
            ),
            value: customer,
          ),
      ],
      control: FSelectControl.managed(
        initial: widget.initialValue,
        onChange: widget.onSelected,
      ),
      searchFieldProperties: FSelectSearchFieldProperties(
        hint: widget.hintText,
        autofocus: true,
      ),
      label: Text(widget.label),
      hint: widget.hintText,
      validator: widget.validator ?? (_) => null,
      clearable: true,
    );
  }
}
