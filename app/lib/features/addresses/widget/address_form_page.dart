import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class AddressFormPage extends StatefulWidget {
  final Address? address;
  final bool readOnly;

  const AddressFormPage({super.key, this.address, this.readOnly = false});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AddressService();

  late final TextEditingController _nameController;
  bool _saving = false;

  bool get _isEditing => widget.address != null;
  String get _toastMessage => _isEditing ? 'Endereço atualizado com sucesso.' : 'Endereço criado com sucesso.';
  String get _title => widget.readOnly ? 'Visualizar Endereço' : (_isEditing ? 'Editar Endereço' : 'Novo Endereço');

  @override
  void initState() {
    super.initState();

    final name = switch (widget.address) {
      Address(:final name) => name,
      null => '',
    };

    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    try {
      final address = Address(
        id: widget.address?.id,
        name: _nameController.text.trim(),
      );
      if (_isEditing) {
        await _service.update(address);
      } else {
        await _service.create(address);
      }
      if (mounted) {
        AppToast.success(context, _toastMessage);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorCode = e is ApiException ? ApiErrorCode.fromCode(e.code) : null;
        AppToast.error(context, errorCode?.description ?? 'Erro ao salvar endereço.');
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
      fields: FTextFormField(
        control: FTextFieldControl.managed(controller: _nameController),
        label: const Text('Endereço'),
        hint: 'Digite o logradouro com tipo (ex: Rua das Flores)',
        readOnly: widget.readOnly,
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
      ),
    );
  }
}
