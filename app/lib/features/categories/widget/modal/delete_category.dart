import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/shared/widgets/delete_confirm_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> deleteCategory(BuildContext context, CategoryService service, Category category) async {
  final confirmed = await showDeleteConfirmDialog(
    context: context,
    title: 'Excluir categoria',
    message: 'Deseja excluir "${category.name}"?',
  );
  if (!confirmed) return false;
  await service.delete(category.id!);
  return true;
}
