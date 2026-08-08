import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A preloaded combobox for picking an [Address] — it loads the full
/// address list once and lets the user pick from it (no search-as-you-type),
/// grouped by [Address.kind] and sorted alphabetically within each kind.
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

  List<FSelectItemMixin> _sections(List<Address> addresses) {
    final sorted = [...addresses]..sort((a, b) {
        final byKind = kinds.indexOf(a.kind).compareTo(kinds.indexOf(b.kind));
        return byKind != 0 ? byKind : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final byKind = <String, List<Address>>{};
    for (final address in sorted) {
      byKind.putIfAbsent(address.kind, () => []).add(address);
    }

    return [
      for (final entry in byKind.entries)
        FSelectSection<Address>(
          label: Text(entry.key),
          items: {for (final address in entry.value) address.name: address},
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Address>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;

        return FSelect<Address>.rich(
          format: (a) => a.fullAddress,
          control: FSelectControl.managed(initial: widget.initialValue, onChange: widget.onSelected),
          label: Text(widget.label),
          hint: loading ? 'Carregando...' : 'Selecione o logradouro',
          enabled: !loading,
          validator: widget.validator ?? (_) => null,
          children: loading ? const [] : _sections(snapshot.data!),
        );
      },
    );
  }
}
