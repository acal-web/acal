import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class AddressKindSelect extends StatelessWidget {
  const AddressKindSelect({super.key, this.value = 'Todos', this.onChanged = _noop});

  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> _kinds = const ['Todos', ...kinds];

  static void _noop(String? _) {}

  @override
  Widget build(BuildContext context) {
    return FSelect<String>(
      items: {for (final t in _kinds) t: t},
      control: FSelectControl.managed(initial: value, onChange: onChanged),
    );
  }
}
