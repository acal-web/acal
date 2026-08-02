import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/labeled_field.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerFormPage extends StatefulWidget {
  final Customer? customer;

  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();

  late final TextEditingController _nameController;
  late final TextEditingController _documentController;
  late final TextEditingController _membershipNumberController;
  late bool _voter;
  bool _saving = false;

  bool get _isEditing => widget.customer != null;
  String get _toastMessage => _isEditing ? 'Sócio atualizado com sucesso.' : 'Sócio criado com sucesso.';
  String get _title => _isEditing ? 'Editar Sócio' : 'Novo Sócio';

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _documentController = TextEditingController(text: customer?.document ?? '');
    _membershipNumberController = TextEditingController(text: customer?.membershipNumber.toString() ?? '');
    _voter = customer?.voter ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _membershipNumberController.dispose();
    super.dispose();
  }

  String? _validateDocument(String? v) {
    final digits = v?.trim() ?? '';
    if (digits.isEmpty) return 'Obrigatório';
    if (digits.length != 11 && digits.length != 14) return 'Deve ter 11 (CPF) ou 14 (CNPJ) dígitos';
    return null;
  }

  String? _validateMembershipNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obrigatório';
    final parsed = int.tryParse(v.trim());
    if (parsed == null || parsed <= 0) return 'Número inválido';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);
    try {
      final customer = Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        document: _documentController.text.trim(),
        membershipNumber: int.parse(_membershipNumberController.text.trim()),
        voter: _voter,
      );
      if (_isEditing) {
        await _service.update(customer);
      } else {
        await _service.create(customer);
      }
      if (mounted) {
        AppToast.success(context, _toastMessage);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final errorCode = e is ApiException ? ApiErrorCode.fromCode(e.code) : null;
        AppToast.error(context, errorCode?.description ?? 'Erro ao salvar sócio.');
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
          LabeledField(
            label: 'Nome',
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite o nome do sócio',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Documento (CPF ou CNPJ)',
            child: TextFormField(
              controller: _documentController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Somente números',
              ),
              validator: _validateDocument,
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Número de Sócio',
            child: TextFormField(
              controller: _membershipNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: _validateMembershipNumber,
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _voter,
            onChanged: (v) => setState(() => _voter = v ?? false),
            title: const Text('É votante'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
