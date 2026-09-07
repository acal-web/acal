import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/features/customer/widget/customer_form_page.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> openCustomer(
  BuildContext context, {
  Customer? customer,
  bool readOnly = false,
  CustomerService? customerService,
}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => CustomerFormPage(customer: customer, readOnly: readOnly, customerService: customerService),
  );
  return saved == true;
}
