import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A preloaded combobox for picking an [Address] — it loads the full
/// address list once and lets the user pick from it (no search-as-you-type),
/// sorted alphabetically by name.
class AddressSelectField extends StatefulWidget {
  const AddressSelectField({
    super.key,
    required this.addressService,
    this.initialValue,
    required this.onSelected,
    this.label = 'Logradouro',
    this.validator,
  });

  final AddressService addressService;
  final Address? initialValue;
  final ValueChanged<Address?> onSelected;
  final String label;
  final FormFieldValidator<Address>? validator;

  @override
  State<AddressSelectField> createState() => _AddressSelectFieldState();
}

class _AddressSelectFieldState extends State<AddressSelectField> {
  late final Future<List<Address>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.addressService.findAll(size: 500).then((r) => r.data);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Address>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final addresses = snapshot.data ?? [];
        final sorted = [...addresses]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return FSelect<Address>.rich(
          format: (a) => a.name,
          control: FSelectControl.managed(initial: widget.initialValue, onChange: widget.onSelected),
          label: Text(widget.label),
          hint: loading ? 'Carregando...' : 'Selecione o logradouro',
          enabled: !loading,
          validator: widget.validator ?? (_) => null,
          children: loading
              ? const []
              : [
                  FSelectSection<Address>(
                    label: const Text('Endereços'),
                    items: {for (final address in sorted) address.name: address},
                  ),
                ],
        );
      },
    );
  }
}
