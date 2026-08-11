import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/document_form_field.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

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
  late DocumentKind _documentKind;
  late bool _voter;
  bool _saving = false;

  bool get _isEditing => widget.customer != null;
  String get _toastMessage => _isEditing ? 'Sócio atualizado com sucesso.' : 'Sócio criado com sucesso.';
  String get _title => _isEditing ? 'Editar Sócio' : 'Novo Sócio';

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;
    final documentDigits = customer?.document.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    _documentKind = DocumentKind.fromDigits(documentDigits) ?? DocumentKind.cpf;

    _nameController = TextEditingController(text: customer?.name ?? '');
    _documentController = TextEditingController(text: maskDocument(documentDigits, _documentKind));
    _membershipNumberController = TextEditingController(text: customer?.membershipNumber?.toString() ?? '');
    _voter = customer?.voter ?? true;
  }

  void _toggleDocumentKind() {
    setState(() {
      _documentKind = _documentKind == DocumentKind.cpf ? DocumentKind.cnpj : DocumentKind.cpf;

      final digits = _documentController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final capped = digits.length > _documentKind.maxDigits ? digits.substring(0, _documentKind.maxDigits) : digits;
      final formatted = maskDocument(capped, _documentKind);
      _documentController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _membershipNumberController.dispose();
    super.dispose();
  }


  String? _validateMembershipNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
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
        document: _documentController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        membershipNumber: _membershipNumberController.text.trim().isEmpty
            ? null
            : int.parse(_membershipNumberController.text.trim()),
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
        AppToast.error(context, _errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorMessage(Object e) {
    if (e is! ApiException) return 'Erro ao salvar sócio.';

    final errorCode = ApiErrorCode.fromCode(e.code);
    if (errorCode != null) return errorCode.description;

    return e.fieldError('document') ?? 'Erro ao salvar sócio.';
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
          const Divider(),
          FTextFormField(
            control: FTextFieldControl.managed(controller: _nameController),
            label: const Text('Nome'),
            hint: 'Digite o nome do sócio',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
          ),
          
          const SizedBox(height: 12),
          DocumentFormField(
            controller: _documentController,
            documentKind: _documentKind,
            onToggleKind: _toggleDocumentKind,
          ),
          const SizedBox(height: 12),
          FTextFormField(
            control: FTextFieldControl.managed(controller: _membershipNumberController),
            label: const Text('Número de Sócio (opcional)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateMembershipNumber,
          ),
          const SizedBox(height: 12),
          FCheckbox(
            value: _voter,
            onChange: (v) => setState(() => _voter = v),
            label: const Text('É votante'),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
