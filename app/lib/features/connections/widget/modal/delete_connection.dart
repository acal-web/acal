import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/shared/widgets/delete_confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> deleteConnection(BuildContext context, ConnectionService service, Connection connection) async {
  final confirmed = await showDeleteConfirmDialog(
    context: context,
    title: 'Excluir ligação',
    message: 'Deseja excluir a ligação de "${connection.customer?.name}" em "${connection.address?.fullAddress}"?',
  );
  if (!confirmed) return false;
  await service.delete(connection.id!);
  return true;
}
