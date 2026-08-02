import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/widget/connection_form_page.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> openConnection(BuildContext context, {Connection? connection}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => ConnectionFormPage(connection: connection),
  );
  return saved == true;
}
