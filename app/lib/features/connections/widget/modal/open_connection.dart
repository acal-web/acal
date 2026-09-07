import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/connections/widget/connection_form_page.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> openConnection(
  BuildContext context, {
  Connection? connection,
  ConnectionService? connectionService,
  CustomerService? customerService,
  AddressService? addressService,
  CategoryService? categoryService,
}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => ConnectionFormPage(
      connection: connection,
      connectionService: connectionService,
      customerService: customerService,
      addressService: addressService,
      categoryService: categoryService,
    ),
  );
  return saved == true;
}
