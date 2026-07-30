import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:flutter/material.dart';

class AddressFormPage extends StatefulWidget {
  final Address? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AddressService();

  late String _kind;
  late final TextEditingController _nameController;
  bool _saving = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();

    final (kind, name) = switch (widget.address) {
      Address(:final kind, :final name) => (kind, name),
      null => (kinds.first, ''),
    };

    _kind = kind;
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
        kind: _kind,
        name: _nameController.text.trim(),
      );
      if (_isEditing) {
        await _service.update(address);
      } else {
        await _service.create(address);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFormDialog(
      formKey: _formKey,
      title: _isEditing ? 'Editar Endereço' : 'Novo Endereço',
      onSave: _save,
      saving: _saving,
      fields: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LabeledField(
              label: 'Tipo',
              child: DropdownButtonFormField<String>(
                initialValue: _kind,
                items: kinds
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {},
                onSaved: (v) => _kind = v!,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Obrigatório' : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: LabeledField(
              label: 'Nome',
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Digite o logradouro',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
