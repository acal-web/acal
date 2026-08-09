import 'package:acalapp/shared/widgets/table/collapsible_filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Collapsible "Filtros" panel with a single name search field, used by
/// "Cadastros" pages whose backend only filters by name (e.g. Logradouros,
/// Categorias). Pages needing more than one filter field define their own
/// filter bar instead (see `CustomerFilterBar`, `ConnectionFilterBar`).
class NameFilterBar extends StatefulWidget {
  const NameFilterBar({super.key, required this.label, required this.onSearch});

  /// Field label, e.g. 'Logradouro:'.
  final String label;
  final void Function({String? name}) onSearch;

  @override
  State<NameFilterBar> createState() => _NameFilterBarState();
}

class _NameFilterBarState extends State<NameFilterBar> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _search() => widget.onSearch(name: _nameController.text.trim());

  void _clear() {
    setState(_nameController.clear);
    widget.onSearch();
  }

  @override
  Widget build(BuildContext context) {
    return CollapsibleFilterPanel(
      builder: (context, narrow) {
        final nameField = FTextField(
          control: FTextFieldControl.managed(controller: _nameController),
          label: Text(widget.label),
          hint: 'Buscar por nome:',
          onSubmit: (_) => _search(),
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

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameField,
              const SizedBox(height: 8),
              Row(
                children: [
                  clearButtonNarrow,
                  const SizedBox(width: 8),
                  searchButtonNarrow,
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: nameField),
                const SizedBox(width: 8),
                const Spacer(flex: 6),
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
      },
    );
  }
}
