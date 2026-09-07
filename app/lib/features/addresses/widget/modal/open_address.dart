import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_form_page.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> openAddress(
  BuildContext context, {
  Address? address,
  bool readOnly = false,
  AddressService? addressService,
}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => AddressFormPage(address: address, readOnly: readOnly, addressService: addressService),
  );
  return saved == true;
}
