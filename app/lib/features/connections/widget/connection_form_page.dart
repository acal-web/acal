import 'package:acalapp/core/services/api_error_code.dart';
import 'package:acalapp/core/services/http_service.dart';
import 'package:acalapp/features/addresses/data/address_service.dart';
import 'package:acalapp/features/addresses/domain/address.dart';
import 'package:acalapp/features/addresses/widget/address_select_field.dart';
import 'package:acalapp/features/categories/data/category_service.dart';
import 'package:acalapp/features/categories/domain/category.dart';
import 'package:acalapp/features/categories/widget/category_select_field.dart';
import 'package:acalapp/features/connections/data/connection_service.dart';
import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:acalapp/features/customer/data/customer_service.dart';
import 'package:acalapp/features/customer/domain/customer.dart';
import 'package:acalapp/shared/widgets/app_form_dialog.dart';
import 'package:acalapp/shared/widgets/search_select_field.dart';
import 'package:acalapp/shared/widgets/toast/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

class ConnectionFormPage extends StatefulWidget {
  final Connection? connection;
  final ConnectionService? connectionService;
  final CustomerService? customerService;
  final AddressService? addressService;
  final CategoryService? categoryService;

  const ConnectionFormPage({
    super.key,
    this.connection,
    this.connectionService,
    this.customerService,
    this.addressService,
    this.categoryService,
  });

  @override
  State<ConnectionFormPage> createState() => _ConnectionFormPageState();
}

class _ConnectionFormPageState extends State<ConnectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ConnectionService _service;
  late final CustomerService _customerService;
  late final AddressService _addressService;
  late final CategoryService _categoryService;

  Customer? _selectedCustomer;
  Address? _selectedAddress;
  Category? _selectedCategory;
  late final TextEditingController _numberController;
  late final TextEditingController _letterController;
  late bool _active;
  DateTime? _membershipDate;
  late final TextEditingController _membershipDateController;
  late bool _exclusivelyMember;
  bool _saving = false;

  bool get _isEditing => widget.connection != null;
  String get _toastMessage => _isEditing ? 'Ligação atualizada com sucesso.' : 'Ligação criada com sucesso.';
  String get _title => _isEditing ? 'Editar Ligação' : 'Nova Ligação';

  @override
  void initState() {
    super.initState();
    _service = widget.connectionService ?? ConnectionService();
    _customerService = widget.customerService ?? CustomerService();
    _addressService = widget.addressService ?? AddressService();
    _categoryService = widget.categoryService ?? CategoryService();

    _selectedCustomer = widget.connection?.customer;
    _selectedAddress = widget.connection?.address;
    _selectedCategory = widget.connection?.category;
    _numberController = TextEditingController(text: widget.connection?.number.toString() ?? '');
    _letterController = TextEditingController(text: widget.connection?.letter ?? '');
    _active = widget.connection?.active ?? true;
    _membershipDate = widget.connection?.membershipDate;
    _membershipDateController = TextEditingController(
      text: _membershipDate != null ? _formatDate(_membershipDate!) : '',
    );
    _exclusivelyMember = widget.connection?.exclusivelyMember ?? false;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _letterController.dispose();
    _membershipDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _pickMembershipDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _membershipDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _membershipDate = picked;
        _membershipDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final letter = _letterController.text.trim();
      final connection = Connection(
        id: widget.connection?.id,
        customerId: _selectedCustomer!.id!,
        addressId: _selectedAddress!.id!,
        categoryId: _selectedCategory!.id!,
        number: int.parse(_numberController.text.trim()),
        letter: letter.isEmpty ? null : letter,
        active: _active,
        membershipDate: _membershipDate,
        exclusivelyMember: _exclusivelyMember,
      );
      if (_isEditing) {
        await _service.update(connection);
      } else {
        await _service.create(connection);
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
    if (e is! ApiException) return 'Erro ao salvar ligação.';

    final errorCode = ApiErrorCode.fromCode(e.code);
    if (errorCode != null) return errorCode.description;

    if (e.fieldError('address_id') != null) {
      return 'Este logradouro já está com uma ligação ativa.';
    }
    if (e.fieldError('customer_id') != null) {
      return 'Este sócio já está recebendo outra ligação como efetivo.';
    }

    return 'Erro ao salvar ligação.';
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
          SearchSelectField<Customer>(
            label: 'Sócio',
            hintText: 'Buscar sócio por nome',
            initialValue: _selectedCustomer,
            search: (query) => _customerService.findAll(name: query, size: 10).then((r) => r.data),
            labelBuilder: (c) => c.name,
            subtitleBuilder: (c) => c.document,
            onSelected: (c) => setState(() => _selectedCustomer = c),
            validator: (c) => c == null ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          AddressSelectField(
            addressService: _addressService,
            initialValue: _selectedAddress,
            onSelected: (a) => setState(() => _selectedAddress = a),
            validator: (a) => a == null ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: FTextFormField(
                  control: FTextFieldControl.managed(controller: _numberController),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  label: const Text('Número'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FTextFormField(
                  control: FTextFieldControl.managed(controller: _letterController),
                  maxLength: 1,
                  textCapitalization: TextCapitalization.characters,
                  label: const Text('Letra'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CategorySelectField(
            categoryService: _categoryService,
            initialValue: _selectedCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
            validator: (c) => c == null ? 'Obrigatório' : null,
          ),
          const SizedBox(height: 12),
          FTextFormField(
            control: FTextFieldControl.managed(controller: _membershipDateController),
            readOnly: true,
            label: const Text('Data da Matrícula'),
            hint: 'Selecione a data',
            suffixBuilder: (context, style, variants) => const Icon(Icons.calendar_today, size: 18),
            onTap: _pickMembershipDate,
          ),
          const SizedBox(height: 12),
          FCheckbox(
            value: _active,
            onChange: (v) => setState(() => _active = v),
            label: const Text('Ativa'),
          ),
          FCheckbox(
            value: _exclusivelyMember,
            onChange: (v) => setState(() => _exclusivelyMember = v),
            label: const Text('Exclusivamente Sócio'),
          ),
        ],
      ),
    );
  }
}
