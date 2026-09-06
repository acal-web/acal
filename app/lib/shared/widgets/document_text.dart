import 'package:acalapp/shared/formatters/digits.dart';
import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:flutter/material.dart';

String formatDocument(String value) {
  final digits = onlyDigits(value);
  final kind = DocumentKind.fromDigits(digits);
  return kind == null ? value : maskDocument(digits, kind);
}

class DocumentText extends StatelessWidget {
  const DocumentText(this.document, {super.key, this.style});

  final String document;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(formatDocument(document), style: style);
}
