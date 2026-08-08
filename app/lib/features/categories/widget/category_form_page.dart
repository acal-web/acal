import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CategoryFormPage extends StatefulWidget {
  final Category? category;

  const CategoryFormPage({super.key, this.category});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = CategoryService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _waterPriceController;
  late final TextEditingController _membershipPriceController;
  late String _group;
  late bool _hasWaterMeter;
  bool _saving = false;

  bool get _isEditing => widget.category != null;
  String get _toastMessage => _isEditing ? 'Categoria atualizada com sucesso.' : 'Categoria criada com sucesso.';
  String get _title => _isEditing ? 'Editar Categoria' : 'Nova Categoria';

  @override
  void initState() {
    super.initState();

    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _descriptionController = TextEditingController(text: category?.description ?? '');
    _waterPriceController = TextEditingController(text: category != null ? formatBRL(category.waterPrice) : '');
    _membershipPriceController =
        TextEditingController(text: category != null ? formatBRL(category.membershipPrice) : '');
    _group = category?.group ?? groups.first;
    _hasWaterMeter = category?.hasWaterMeter ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _waterPriceController.dispose();
    _membershipPriceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    try {
      final category = Category(
        id: widget.category?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        group: _group,
        hasWaterMeter: _hasWaterMeter,
        waterPrice: parseBRL(_waterPriceController.text),
        membershipPrice: parseBRL(_membershipPriceController.text),
      );
      if (_isEditing) {
        await _service.update(category);
      } else {
        await _service.create(category);
      }
      if (mounted) {
        AppToast.success(context, _toastMessage);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorCode = e is ApiException ? ApiErrorCode.fromCode(e.code) : null;
        AppToast.error(context, errorCode?.description ?? 'Erro ao salvar categoria.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      formKey: _formKey,
      title: _title,
      onSave: _save,
      saving: _saving,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FTextFormField(
            control: FTextFieldControl.managed(controller: _nameController),
            label: const Text('Nome'),
            hint: 'Digite o nome da categoria',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          FTextFormField(
            control: FTextFieldControl.managed(controller: _descriptionController),
            maxLines: 2,
            label: const Text('Descrição'),
            hint: 'Digite a descrição',
          ),
          const SizedBox(height: 12),
          FSelect<String>(
            items: {for (final g in groups) groupLabel(g): g},
            control: FSelectControl.managed(initial: _group, onChange: (v) {}),
            label: const Text('Grupo'),
            onSaved: (v) => _group = v!,
            validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  identifier: 'water-price-field',
                  child: FTextFormField(
                    control: FTextFieldControl.managed(controller: _waterPriceController),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    label: const Text('Valor da Água'),
                    validator: _validatePrice,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  identifier: 'membership-price-field',
                  child: FTextFormField(
                    control: FTextFieldControl.managed(controller: _membershipPriceController),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    label: const Text('Valor Societário'),
                    validator: _validatePrice,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FCheckbox(
            value: _hasWaterMeter,
            onChange: (v) => setState(() => _hasWaterMeter = v),
            label: const Text('Possui hidrômetro'),
          ),
        ],
      ),
    );
  }
}
