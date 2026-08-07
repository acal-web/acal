import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:flutter/material.dart';

const _narrowBreakpoint = 640.0;

class CustomerFilterBar extends StatefulWidget {
  const CustomerFilterBar({super.key, required this.onSearch});

  final void Function({String? name, String? document}) onSearch;

  @override
  State<CustomerFilterBar> createState() => _CustomerFilterBarState();
}

class _CustomerFilterBarState extends State<CustomerFilterBar> {
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  DocumentKind _documentKind = DocumentKind.cpf;
  bool _expanded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  void _toggleDocumentKind() {
    setState(() {
      _documentKind = _documentKind == DocumentKind.cpf ? DocumentKind.cnpj : DocumentKind.cpf;

      final digits = _documentController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final capped = digits.length > _documentKind.maxDigits ? digits.substring(0, _documentKind.maxDigits) : digits;
      final formatted = maskDocument(capped, _documentKind);
      _documentController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  void _search() => widget.onSearch(
        name: _nameController.text.trim(),
        document: _documentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

  void _clear() {
    setState(() {
      _nameController.clear();
      _documentController.clear();
      _documentKind = DocumentKind.cpf;
    });
    widget.onSearch();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < _narrowBreakpoint;

        final nameField = LabeledField(
          label: 'Nome:',
          child: TextField(
            controller: _nameController,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Buscar por nome:',
            ),
            onSubmitted: (_) => _search(),
          ),
        );

        final isCpf = _documentKind == DocumentKind.cpf;

        final documentField = LabeledField(
          label: isCpf ? 'Documento (CPF):' : 'Documento (CNPJ):',
          child: TextField(
            controller: _documentController,
            keyboardType: TextInputType.number,
            inputFormatters: [DocumentInputFormatter(_documentKind)],
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: isCpf ? '000.000.000-00' : '00.000.000/0000-00',
              prefixIcon: IconButton(
                icon: Icon(isCpf ? Icons.person : Icons.business),
                tooltip: isCpf
                    ? 'Pessoa física (CPF) — toque para alternar para CNPJ'
                    : 'Pessoa jurídica (CNPJ) — toque para alternar para CPF',
                onPressed: _toggleDocumentKind,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
        );

        final searchButtonNarrow = Expanded(
          child: FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Consultar'),
          ),
        );

        final clearButtonNarrow = Expanded(
          child: OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Limpar'),
          ),
        );

        final searchButtonWide = SizedBox(
          child: FilledButton.icon(
            onPressed: _search,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Consultar'),
          ),
        );

        final clearButtonWide = SizedBox(
          child: OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Limpar'),
          ),
        );

        final fields = narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nameField,
                  const SizedBox(height: 8),
                  documentField,
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
                      Expanded(flex: 9, child: nameField),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: documentField),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Bootstrap-equivalent: offset-8, then two col-2 buttons —
                      // buttons occupy the right-hand third of the row, split evenly.
                      const Spacer(flex: 8),
                      Expanded(flex: 2, child: clearButtonWide),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: searchButtonWide),
                    ],
                  ),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                          child: Padding(
                            padding: EdgeInsets.all(narrow ? 12 : 16),
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
