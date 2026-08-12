import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/widget/category_form_page.dart';
import 'package:acalapp/shared/widgets/blurred_dialog.dart';
import 'package:flutter/material.dart';

Future<bool> openCategory(BuildContext context, {Category? category, bool readOnly = false}) async {
  final saved = await showBlurredDialog<bool>(
    context: context,
    builder: (context) => CategoryFormPage(category: category, readOnly: readOnly),
  );
  return saved == true;
}
