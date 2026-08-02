import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:acalapp/shared/widgets/search_select_field.dart';
import 'package:flutter/material.dart';

const _actionButtonWidth = 180.0;
const _narrowBreakpoint = 640.0;

typedef ConnectionFilters = ({
  String? customerName,
  String? customerDocument,
  String? addressName,
  String? categoryId,
  bool? active,
});

class ConnectionFilterBar extends StatefulWidget {
  const ConnectionFilterBar({super.key, required this.onSearch, this.categoryService});

  final void Function(ConnectionFilters filters) onSearch;
  final CategoryService? categoryService;

  @override
  State<ConnectionFilterBar> createState() => _ConnectionFilterBarState();
}

class _ConnectionFilterBarState extends State<ConnectionFilterBar> {
  late final CategoryService _categoryService;
  final _customerNameController = TextEditingController();
  final _customerDocumentController = TextEditingController();
  final _addressNameController = TextEditingController();
  Category? _category;
  bool? _active;

  @override
  void initState() {
    super.initState();
    _categoryService = widget.categoryService ?? CategoryService();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerDocumentController.dispose();
    _addressNameController.dispose();
    super.dispose();
  }

  void _search() => widget.onSearch((
        customerName: _customerNameController.text.trim(),
        customerDocument: _customerDocumentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        addressName: _addressNameController.text.trim(),
        categoryId: _category?.id,
        active: _active,
      ));

  void _clear() {
    setState(() {
      _customerNameController.clear();
      _customerDocumentController.clear();
      _addressNameController.clear();
      _category = null;
      _active = null;
    });
    widget.onSearch((customerName: null, customerDocument: null, addressName: null, categoryId: null, active: null));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreakpoint;

        final customerNameField = LabeledField(
          label: 'Sócio',
          child: TextField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Buscar por nome',
            ),
            onSubmitted: (_) => _search(),
          ),
        );

        final customerDocumentField = LabeledField(
          label: 'Documento',
          child: TextField(
            controller: _customerDocumentController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'CPF ou CNPJ',
            ),
            onSubmitted: (_) => _search(),
          ),
        );

        final addressNameField = LabeledField(
          label: 'Logradouro',
          child: TextField(
            controller: _addressNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Buscar por nome',
            ),
            onSubmitted: (_) => _search(),
          ),
        );

        final categoryField = SearchSelectField<Category>(
          label: 'Categoria',
          hintText: 'Buscar categoria por nome',
          initialValue: _category,
          search: (query) => _categoryService.findAll(name: query, size: 10).then((r) => r.data),
          labelBuilder: (c) => c.name,
          onSelected: (c) => _category = c,
        );

        final activeField = LabeledField(
          label: 'Situação',
          child: DropdownButtonFormField<bool?>(
            initialValue: _active,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todas')),
              DropdownMenuItem(value: true, child: Text('Ativas')),
              DropdownMenuItem(value: false, child: Text('Encerradas')),
            ],
            onChanged: (v) => setState(() => _active = v),
          ),
        );

        final searchButton = SizedBox(
          width: narrow ? double.infinity : _actionButtonWidth,
          child: FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Consultar'),
          ),
        );

        final clearButton = SizedBox(
          width: narrow ? double.infinity : _actionButtonWidth,
          child: OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Limpar'),
          ),
        );

        // Matches LabeledField's label + gap height with an invisible label,
        // so the button lines up with the category/situação fields instead of
        // sitting shorter and higher than them. Left at its natural height
        // (rather than IntrinsicHeight) because categoryField's SearchSelectField
        // can grow a shrink-wrapped suggestions list that doesn't support
        // intrinsic sizing.
        final clearButtonWide = SizedBox(
          width: _actionButtonWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Opacity(
                opacity: 0,
                child: Text(' ', style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpar'),
              ),
            ],
          ),
        );

        final fields = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  customerNameField,
                  const SizedBox(height: 12),
                  customerDocumentField,
                  const SizedBox(height: 12),
                  addressNameField,
                  const SizedBox(height: 12),
                  categoryField,
                  const SizedBox(height: 12),
                  activeField,
                  const SizedBox(height: 12),
                  clearButton,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: customerNameField),
                      const SizedBox(width: 12),
                      Expanded(child: customerDocumentField),
                      const SizedBox(width: 12),
                      Expanded(child: addressNameField),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: categoryField),
                      const SizedBox(width: 12),
                      Expanded(child: activeField),
                      const SizedBox(width: 12),
                      clearButtonWide,
                    ],
                  ),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: searchButton,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(narrow ? 16 : 24),
                child: fields,
              ),
            ),
          ],
        );
      },
    );
  }
}
