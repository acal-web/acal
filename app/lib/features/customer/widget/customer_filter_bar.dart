import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:flutter/material.dart';

const _actionButtonWidth = 180.0;
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
          label: 'Nome',
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Buscar por nome',
            ),
            onSubmitted: (_) => _search(),
          ),
        );

        final documentField = LabeledField(
          label: _documentKind == DocumentKind.cpf ? 'Documento (CPF)' : 'Documento (CNPJ)',
          child: TextField(
            controller: _documentController,
            keyboardType: TextInputType.number,
            inputFormatters: [DocumentInputFormatter(_documentKind)],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: _documentKind == DocumentKind.cpf ? '000.000.000-00' : '00.000.000/0000-00',
              prefixIcon: IconButton(
                icon: Icon(_documentKind == DocumentKind.cpf ? Icons.person : Icons.business),
                tooltip: _documentKind == DocumentKind.cpf
                    ? 'Pessoa física (CPF) — toque para alternar para CNPJ'
                    : 'Pessoa jurídica (CNPJ) — toque para alternar para CPF',
                onPressed: _toggleDocumentKind,
              ),
            ),
            onSubmitted: (_) => _search(),
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

        final clearButtonNarrow = SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clear,
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Limpar'),
          ),
        );

        // Matches LabeledField's label + gap height with an invisible label,
        // so the button (stretched via IntrinsicHeight) lines up with the
        // text fields instead of sitting shorter and higher than them.
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Limpar'),
                ),
              ),
            ],
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
                  clearButtonNarrow,
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: nameField),
                    const SizedBox(width: 8),
                    Expanded(child: documentField),
                    const SizedBox(width: 8),
                    clearButtonWide,
                  ],
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: searchButton,
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(narrow ? 12 : 16),
                child: fields,
              ),
            ),
          ],
        );
      },
    );
  }
}
