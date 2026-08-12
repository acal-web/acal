import 'package:acalapp/core/config/layout_config.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

enum _ActiveFilter {
  active,
  inactive,
  all;

  bool? get value => switch (this) {
        _ActiveFilter.active => true,
        _ActiveFilter.inactive => false,
        _ActiveFilter.all => null,
      };
}

class AddressFilterBar extends StatefulWidget {
  const AddressFilterBar({super.key, required this.onSearch});

  final void Function({String? name, required bool? active}) onSearch;

  @override
  State<AddressFilterBar> createState() => _AddressFilterBarState();
}

class _AddressFilterBarState extends State<AddressFilterBar> {
  final _nameController = TextEditingController();
  _ActiveFilter _active = _ActiveFilter.active;
  bool _expanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _search() => widget.onSearch(
        name: _nameController.text.trim(),
        active: _active.value,
      );

  void _clear() {
    setState(() {
      _nameController.clear();
      _active = _ActiveFilter.active;
    });
    widget.onSearch(active: true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < LayoutConfig.narrowBreakpoint;

        final nameField = FTextField(
          control: FTextFieldControl.managed(controller: _nameController),
          label: const Text('Logradouro:'),
          hint: 'Buscar por nome:',
          onSubmit: (_) => _search(),
        );

        final activeField = FSelect<_ActiveFilter>(
          items: const {
            'Ativos': _ActiveFilter.active,
            'Inativos': _ActiveFilter.inactive,
            'Todos': _ActiveFilter.all,
          },
          control: FSelectControl.managed(
            initial: _active,
            onChange: (v) => setState(() => _active = v ?? _ActiveFilter.active),
          ),
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
                  nameField,
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
                      Expanded(flex: 6, child: nameField),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: activeField),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
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
