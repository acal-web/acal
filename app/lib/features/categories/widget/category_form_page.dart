import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/shared/formatters/currency_input_formatter.dart';
import 'package:acalapp/shared/validators/required_validator.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class CategoryFormPage extends StatefulWidget {
  final Category? category;
  final bool readOnly;
  final CategoryService? categoryService;

  const CategoryFormPage({super.key, this.category, this.readOnly = false, this.categoryService});

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _service = widget.categoryService ?? CategoryService();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _waterPriceController;
  late final TextEditingController _membershipPriceController;
  late String _group;
  late bool _hasWaterMeter;
  bool _saving = false;

  bool get _isEditing => widget.category != null;
  String get _toastMessage => _isEditing ? 'Categoria atualizada com sucesso.' : 'Categoria criada com sucesso.';

  String get _title {
    if (widget.readOnly) return 'Visualizar Categoria';
    return _isEditing ? 'Editar Categoria' : 'Nova Categoria';
  }

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
      readOnly: widget.readOnly,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FTextFormField(
            key: const Key('category_form_name_field'),
            control: FTextFieldControl.managed(controller: _nameController),
            label: const Text('Nome'),
            hint: 'Digite o nome da categoria',
            readOnly: widget.readOnly,
            validator: validateRequired,
          ),
          const SizedBox(height: 12),
          FTextFormField(
            key: const Key('category_form_description_field'),
            control: FTextFieldControl.managed(controller: _descriptionController),
            maxLines: 2,
            label: const Text('Descrição'),
            hint: 'Digite a descrição',
            readOnly: widget.readOnly,
          ),
          const SizedBox(height: 12),
          FSelect<String>(
            key: const Key('category_form_group_select'),
            items: {for (final g in groups) groupLabel(g): g},
            control: FSelectControl.managed(initial: _group, onChange: (v) {}),
            label: const Text('Grupo'),
            onSaved: (v) => _group = v!,
            enabled: !widget.readOnly,
            validator: validateRequired,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  identifier: 'water-price-field',
                  child: FTextFormField(
                    key: const Key('category_form_water_price_field'),
                    control: FTextFieldControl.managed(controller: _waterPriceController),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    label: const Text('Valor da Água'),
                    readOnly: widget.readOnly,
                    validator: validateRequired,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  identifier: 'membership-price-field',
                  child: FTextFormField(
                    key: const Key('category_form_membership_price_field'),
                    control: FTextFieldControl.managed(controller: _membershipPriceController),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    label: const Text('Valor Societário'),
                    readOnly: widget.readOnly,
                    validator: validateRequired,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FCheckbox(
            key: const Key('category_form_water_meter_checkbox'),
            value: _hasWaterMeter,
            onChange: widget.readOnly ? null : (v) => setState(() => _hasWaterMeter = v),
            label: const Text('Possui hidrômetro'),
          ),
        ],
      ),
    );
  }
}
