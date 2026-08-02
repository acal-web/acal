import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:flutter/material.dart';

/// A preloaded combobox for picking an [Address] — it loads the full
/// address list once and lets the user pick from it (no search-as-you-type),
/// grouped by [Address.kind] and sorted alphabetically within each kind.
class AddressSelectField extends FormField<Address> {
  AddressSelectField({
    super.key,
    required this.addressService,
    super.initialValue,
    required this.onSelected,
    this.label = 'Logradouro',
    super.validator,
  }) : super(builder: (field) => (field as _AddressSelectFieldState)._build(field.context));

  final AddressService addressService;
  final ValueChanged<Address?> onSelected;
  final String label;

  @override
  FormFieldState<Address> createState() => _AddressSelectFieldState();
}

class _AddressSelectFieldState extends FormFieldState<Address> {
  late final Future<List<Address>> _future;

  @override
  AddressSelectField get widget => super.widget as AddressSelectField;

  @override
  void initState() {
    super.initState();
    _future = widget.addressService.findAll(size: 500).then((r) => r.data);
  }

  DropdownMenuEntry<Address> _headerEntry(BuildContext context, String kind) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return DropdownMenuEntry(
      // A distinct (identity-equal) Address instance per kind header — never
      // matches a real address or another header, so it can't be mistaken
      // for the current selection.
      value: Address(kind: kind, name: kind),
      label: kind,
      enabled: false,
      labelWidget: Text(kind, style: style),
      style: MenuItemButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  List<DropdownMenuEntry<Address>> _entries(BuildContext context, List<Address> addresses) {
    final sorted = [...addresses]..sort((a, b) {
        final byKind = kinds.indexOf(a.kind).compareTo(kinds.indexOf(b.kind));
        return byKind != 0 ? byKind : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    String? currentKind;
    return [
      for (final address in sorted) ...[
        if (address.kind != currentKind) _headerEntry(context, currentKind = address.kind),
        DropdownMenuEntry(
          value: address,
          // The list row just shows the name (it's already under its kind
          // header), but `label` is what fills the field once selected —
          // show the kind there too so the closed field isn't ambiguous.
          label: address.fullAddress,
          labelWidget: Text(address.name),
        ),
      ],
    ];
  }

  Widget _build(BuildContext context) {
    return FutureBuilder<List<Address>>(
      future: _future,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState != ConnectionState.done;
        final entries = loading ? const <DropdownMenuEntry<Address>>[] : _entries(context, snapshot.data!);

        return LabeledField(
          label: widget.label,
          child: DropdownMenu<Address>(
            enabled: !loading,
            initialSelection: value,
            expandedInsets: EdgeInsets.zero,
            selectOnly: true,
            hintText: loading ? 'Carregando...' : 'Selecione o logradouro',
            errorText: hasError ? errorText : null,
            dropdownMenuEntries: entries,
            onSelected: (address) {
              didChange(address);
              widget.onSelected(address);
            },
          ),
        );
      },
    );
  }
}
