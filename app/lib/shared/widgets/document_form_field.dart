import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:acalapp/shared/validators/document_validator.dart';
import 'package:flutter/material.dart' show Icons, MainAxisSize;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class DocumentFormField extends StatelessWidget {
  final TextEditingController controller;
  final DocumentKind documentKind;
  final VoidCallback onToggleKind;
  final bool validate;
  final String? label;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const DocumentFormField({
    super.key,
    required this.controller,
    required this.documentKind,
    required this.onToggleKind,
    this.validate = true,
    this.label,
    this.keyboardType = TextInputType.number,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final hint = documentKind == DocumentKind.cpf ? '000.000.000-00' : '00.000.000/0000-00';
    final defaultLabel = documentKind == DocumentKind.cpf ? 'Documento (CPF)' : 'Documento (CNPJ)';

    return FTextFormField(
      control: FTextFieldControl.managed(controller: controller),
      label: label != null ? Text(label!) : Text(defaultLabel),
      hint: hint,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters ?? [DocumentInputFormatter(documentKind)],
      suffixBuilder: (context, style, variants) => FButton(
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.sm,
        mainAxisSize: MainAxisSize.min,
        semanticsTooltip: documentKind == DocumentKind.cpf
            ? 'Pessoa física (CPF) — toque para alternar para CNPJ'
            : 'Pessoa jurídica (CNPJ) — toque para alternar para CPF',
        onPress: onToggleKind,
        child: Icon(
          documentKind == DocumentKind.cpf ? Icons.person : Icons.business,
          size: 18,
        ),
      ),
      validator: validate ? (v) => validateDocument(v, documentKind) : null,
    );
  }
}
