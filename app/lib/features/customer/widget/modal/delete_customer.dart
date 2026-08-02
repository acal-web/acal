import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/widgets/delete_confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> deleteCustomer(BuildContext context, CustomerService service, Customer customer) async {
  final confirmed = await showDeleteConfirmDialog(
    context: context,
    title: 'Excluir sócio',
    message: 'Deseja excluir "${customer.name}"?',
  );
  if (!confirmed) return false;
  await service.delete(customer.id!);
  return true;
}
