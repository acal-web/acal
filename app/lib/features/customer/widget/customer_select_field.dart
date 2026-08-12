import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/widgets/search_select_field.dart';
import 'package:flutter/widgets.dart';

/// A field that searches for customers by name OR document, showing
/// matching results for selection. Accepts both formatted (123.456.789-09)
/// and unformatted (12345678909) documents. Search results are merged and
/// deduplicated by customer ID.
class CustomerSelectField extends StatelessWidget {
  const CustomerSelectField({
    super.key,
    required this.customerService,
    this.initialValue,
    required this.onSelected,
    this.label = 'Sócio',
    this.hintText = 'Buscar por nome ou documento',
    this.active = true,
    this.validator,
  });

  final CustomerService customerService;
  final Customer? initialValue;
  final ValueChanged<Customer?> onSelected;
  final String label;
  final String hintText;
  final bool? active; // null = search active and inactive; true = active only
  final FormFieldValidator<Customer>? validator;

  Future<List<Customer>> _search(String query) async {
    final hasDigits = RegExp(r'[0-9]').hasMatch(query);
    final pages = await Future.wait([
      customerService.findAll(name: query, size: 5, active: active),
      if (hasDigits) customerService.findAll(document: query, size: 5, active: active),
    ]);
    final seen = <String>{};
    return [
      for (final page in pages)
        for (final customer in page.data)
          if (customer.id != null && seen.add(customer.id!)) customer,
    ];
  }

  @override
  Widget build(BuildContext context) => SearchSelectField<Customer>(
        label: label,
        hintText: hintText,
        initialValue: initialValue,
        search: _search,
        labelBuilder: (c) => c.name,
        subtitleBuilder: (c) => c.document,
        onSelected: onSelected,
        validator: validator,
      );
}
