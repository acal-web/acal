import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:flutter/material.dart';

class AddressKindSelect extends StatelessWidget {
  const AddressKindSelect({super.key, this.value = 'Todos', this.onChanged = _noop});

  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> _kinds = const ['Todos', ...kinds];

  static void _noop(String? _) {}

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: _kinds.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(isDense: true),
    );
  }
}
