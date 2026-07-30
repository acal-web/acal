import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_form_page.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

/// Opens the Novo/Editar Endereço dialog. Returns true if it was saved.
Future<bool> openAddress(BuildContext context, {Address? address}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => AddressFormPage(address: address),
  );
  return saved == true;
}
