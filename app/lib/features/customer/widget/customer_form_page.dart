import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/formatters/digits.dart';
import 'package:acalapp/shared/formatters/document_formatter.dart';
import 'package:acalapp/shared/validators/required_validator.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/document_form_field.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart' show Chip, Divider;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

class CustomerFormPage extends StatefulWidget {
  final Customer? customer;
  final bool readOnly;
  final CustomerService? customerService;

  const CustomerFormPage({super.key, this.customer, this.readOnly = false, this.customerService});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _service = widget.customerService ?? CustomerService();

  late final TextEditingController _nameController;
  late final TextEditingController _documentController;
  late final TextEditingController _membershipNumberController;
  late final TextEditingController _customerCodeController;
  late final TextEditingController _newTagController;
  late DocumentKind _documentKind;
  late bool _voter;
  late List<String> _tags;
  bool _saving = false;

  bool get _isEditing => widget.customer != null;
  String get _toastMessage => _isEditing ? 'Sócio atualizado com sucesso.' : 'Sócio criado com sucesso.';

  String get _title {
    if (widget.readOnly) return 'Visualizar Sócio';
    return _isEditing ? 'Editar Sócio' : 'Novo Sócio';
  }

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;
    final documentDigits = customer == null ? '' : onlyDigits(customer.document);
    _documentKind = DocumentKind.fromDigits(documentDigits) ?? DocumentKind.cpf;

    _nameController = TextEditingController(text: customer?.name ?? '');
    _documentController = TextEditingController(text: maskDocument(documentDigits, _documentKind));
    _membershipNumberController = TextEditingController(text: customer?.membershipNumber?.toString() ?? '');
    _customerCodeController = TextEditingController(text: customer?.customerCode ?? '');
    _newTagController = TextEditingController();
    _voter = customer?.voter ?? true;
    _tags = List.from(customer?.tags ?? []);
  }

  void _toggleDocumentKind() {
    setState(() {
      _documentKind = _documentKind == DocumentKind.cpf ? DocumentKind.cnpj : DocumentKind.cpf;

      final digits = onlyDigits(_documentController.text);
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
    _customerCodeController.dispose();
    _newTagController.dispose();
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
        document: onlyDigits(_documentController.text),
        membershipNumber: _membershipNumberController.text.trim().isEmpty
            ? null
            : int.parse(_membershipNumberController.text.trim()),
        voter: _voter,
        tags: _tags,
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
      readOnly: widget.readOnly,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          FTextFormField(
            control: FTextFieldControl.managed(controller: _nameController),
            label: const Text('Nome'),
            hint: 'Digite o nome do sócio',
            readOnly: widget.readOnly,
            validator: validateRequired,
          ),

          const SizedBox(height: 12),
          DocumentFormField(
            controller: _documentController,
            documentKind: _documentKind,
            onToggleKind: widget.readOnly ? () {} : _toggleDocumentKind,
          ),
          const SizedBox(height: 12),
          FTextFormField(
            control: FTextFieldControl.managed(controller: _membershipNumberController),
            label: const Text('Número de Sócio (opcional)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            readOnly: widget.readOnly,
            validator: _validateMembershipNumber,
          ),
          if (_isEditing) ...[
            const SizedBox(height: 12),
            FTextFormField(
              control: FTextFieldControl.managed(controller: _customerCodeController),
              label: const Text('Código do Cliente'),
              hint: 'Usado pelo sócio para entrar na área do sócio',
              readOnly: true,
            ),
          ],
          const SizedBox(height: 12),
          FCheckbox(
            value: _voter,
            onChange: widget.readOnly ? null : (v) => setState(() => _voter = v),
            label: const Text('É votante'),
          ),
          const SizedBox(height: 16),
          const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (!widget.readOnly) _buildTagInput(),
          const SizedBox(height: 12),
          _buildTagList(),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTagInput() => Row(
        spacing: 8,
        children: [
          Expanded(
            child: FTextFormField(
              control: FTextFieldControl.managed(controller: _newTagController),
              hint: 'Nova tag',
            ),
          ),
          FButton(onPress: _addTag, child: const Text('Adicionar')),
        ],
      );

  Widget _buildTagList() {
    if (_tags.isEmpty) {
      return const Text('Nenhuma tag', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map(_buildTagChip).toList(),
    );
  }

  Widget _buildTagChip(String tag) => Chip(
        label: Text(tag),
        onDeleted: widget.readOnly ? null : () => _removeTag(tag),
      );

  void _addTag() {
    final tag = _newTagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;

    setState(() {
      _tags.add(tag);
      _newTagController.clear();
    });
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));
}
