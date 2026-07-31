import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/shared/widgets/delete_confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> deleteAddress(BuildContext context, AddressService service, Address address) async {
  final confirmed = await showDeleteConfirmDialog(
    context: context,
    title: 'Excluir logradouro',
    message: 'Deseja excluir "${address.fullAddress}"?',
  );
  if (!confirmed) return false;
  await service.delete(address.id!);
  return true;
}
